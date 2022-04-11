#!/bin/bash

set +x

# GCP Metadata URL and Header
GCP_META="http://metadata.google.internal/computeMetadata/v1"
GCP_HEADER="-H \"Metadata-Flavor: Google\""

TELE_VERSION="8.3.4"

# Check teleport systemctl status
STATUS=$(systemctl is-active teleport.service)
if [[ $${STATUS} == 'active' ]]; then
	systemctl stop teleport.service
fi

# Setup teleport data dir used for transient storage
if [ -d /var/lib/teleport ]; then
	rm -fr /var/lib/teleport
fi
mkdir -p /var/lib/teleport/
chown -R root:root /var/lib/teleport

# Setup teleport run dir for pid files
mkdir -p /var/run/teleport/
chown -R root:root /var/run/teleport

# Make exec directory so we can run teleport
mkdir -p /mnt/disks/teleport
mount -t tmpfs tmpfs /mnt/disks/teleport

# Download and install teleport
pushd /tmp || exit
curl -L --retry 100 --retry-delay 0 --connect-timeout 1 --max-time 300 -o teleport.tar.gz https://get.gravitational.com/teleport/$${TELE_VERSION}/teleport-ent-v$${TELE_VERSION}-linux-amd64-bin.tar.gz
tar -xzf /tmp/teleport.tar.gz
cp teleport-ent/tctl teleport-ent/tsh teleport-ent/teleport /mnt/disks/teleport
rm -rf /tmp/teleport.tar.gz /tmp/teleport-ent
popd || return

# Setup teleport proxy server config file
INSTANCE_NAME=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name)
LOCAL_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
LOCAL_HOSTNAME=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/hostname)
IMAGE=$(basename $(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/image))
PROJECT_ID=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/project/project-id)
ID=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/id")

FULL_ZONE_URL=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/zone")
ZONE=$(echo $${FULL_ZONE_URL} | sed 's:.*/::')

echo ${AUTH_TOKEN} > /var/lib/teleport/token


cat >/mnt/disks/teleport/teleport.yaml <<EOF
teleport:
  ca_pin: ${CA_PIN}
  auth_token: /var/lib/teleport/token
  nodename: $${LOCAL_HOSTNAME}
  advertise_ip: $${LOCAL_IP}
  log:
    output: stderr
    severity: INFO
  data_dir: /var/lib/teleport
  auth_servers:
    - ${PROXY_HOST}
auth_service:
  enabled: no
ssh_service:
  enabled: yes
  listen_addr: 0.0.0.0:3022
  labels:
    env: ${ENV}
    instance_id: $${ID}
    image: $${IMAGE}
    group: ${GROUP}
    application: ${APP}
    class: ${CLASS}
    zone: $${ZONE}
proxy_service:
  enabled: no
EOF

# Install and start teleport systemd unit
cat >/etc/systemd/system/teleport.service <<EOF
[Unit]
Description=Teleport SSH Service
After=network.target
[Service]
User=root
Group=root
Type=simple
Restart=always
RestartSec=5
ExecStart=/mnt/disks/teleport/teleport start --config=/mnt/disks/teleport/teleport.yaml --diag-addr=127.0.0.1:3434 --pid-file=/var/run/teleport/teleport.pid
ExecReload=/bin/kill -HUP \$$MAINPID
PIDFile=/var/run/teleport/teleport.pid
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

systemctl enable teleport
systemctl start teleport


# Setup and install Docker/ Docker Deamon and Docker-Compose
# DOCKER_RELEASE_VERSION="20.10.10"

# Check docker systemctl status
DOCKER_STATUS=$(systemctl is-active docker.service)

if [[ $$DOCKER_STATUS == 'active' ]]; then
	systemctl stop docker.service
fi

# Setup docker data dir used for transient storage
if [ -d /var/lib/docker ]; then
	rm -fr /var/lib/docker
fi

# Setup docker run dir for pid files
mkdir -p /var/lib/docker/
chown -R root:adm /lib/run/docker


pushd /tmp || exit
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt -y update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
popd || return

cat >/usr/local/bin/exec-pre-start <<EOF
#!/bin/bash
set -e
set -o pipefail
# Check to make sure PID directory exists
if [ ! -d "/var/run/docker.pid" ]; then
  mkdir -p /var/run/docker.pid/
  chown -R root:adm /var/run/docker.pid
fi

# Enable ipv4 forwarding, required on CIS hardened machines
echo "net.ipv4.conf.all.forwarding=1" > /etc/sysctl.d/enabled_ipv4_forwarding.conf
EOF

chmod 755 /usr/local/bin/exec-pre-start

# Install and start docker systemd unit
cat >/etc/systemd/system/docker.service <<EOF
[Unit]
Description=Docker Service
After=network.target
[Service]
User=root
Group=adm
Type=simple
Restart=always
RestartSec=5
ExecStartPre=/usr/local/bin/exec-pre-start
ExecStart=
ExecReload=/bin/kill -HUP \$$MAINPID
PIDFile=/var/run/docker.pid
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

systemctl enable docker
systemctl start docker


sudo apt -y update
sudo apt install -y net-tools
apt install -y jq

sudo apt -y update
sudo apt -y install curl
sudo apt -y install ping


# sudo apt install -y netstat
# sudo apt install -y rpm

SDA=$(sudo blkid /dev/sda)
FSTAB1=$(cat /etc/fstab)
NAME=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/hostname")
METADATA=$(curl -f -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/?recursive=True" | jq 'del(.["startup-script"])')
DOCKER=$(docker system info)

mkdir /tmp/health-test
touch /tmp/health-test/index.html
chmod 777 /tmp/health-test/index.html


cat >/tmp/health-test/index.html <<EOF
    <h2>Alation Test Internal Webpage</h2>
    <h3>$${NAME}</h3>
    <pre>
        Metadata: $${METADATA}
        SDA: $${SDA}
        /etc/fstab: $${FSTAB1}
        IP: $${IP}
        ID: $${ID}
    </pre>
    <div>
        DOCKER: $${DOCKER}
    </div>
EOF

docker run -d -p 8001:80 --name healthtest -v /tmp/health-test/:/usr/share/nginx/html:ro nginx
