#!/bin/bash
set +x

# GCP Metadata URL and Header
GCP_META="http://metadata.google.internal/computeMetadata/v1"
GCP_HEADER="-H \"Metadata-Flavor: Google\""
# Setup teleport proxy server config file
TELEPORT_ADDR="teleport.exmaple.com:443"

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

FULL_ZONE_URL=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/zone")
ID=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/id")
ZONE=$(echo $${FULL_ZONE_URL} | sed 's:.*/::')

echo "${TELE_TOKEN}" > /var/lib/teleport/token

cat >/mnt/disks/teleport/teleport.yaml <<EOF
teleport:
  ca_pin: ${CA_PIN}
  auth_token: /var/lib/teleport/token
  nodename: ip-$${LOCAL_IP}.${REGION}.compute.internal
  advertise_ip: $${LOCAL_IP}
  log:
    output: stderr
    severity: INFO
  data_dir: /var/lib/teleport
  auth_servers:
    - $${TELEPORT_ADDR}
auth_service:
  enabled: no
ssh_service:
  enabled: yes
  listen_addr: 0.0.0.0:3022
  labels:
    env: ${ENV}
    application: ${APP}
    group: ${GROUP}
    class: ${CLASS}
    type: ${TYPE}
    instance_id: $${ID}
    image: $${IMAGE}
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


# Automate mounting and formatting persistant disk
sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
sudo mkdir -p /mnt/disks/db-disk
sudo mount -o discard,defaults /dev/sdb /mnt/disks/db-disk
sudo chmod a+w /mnt/disks/db-disk
sudo cp /etc/fstab /etc/fstab.backup

SDB_UUID=$(sudo lsblk -f --output UUID --nodeps /dev/sdb --noheadings)
echo UUID=`sudo blkid -s $$SDB_UUID -o value /dev/sdb` /mnt/disks/db-disk ext4 discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab

sudo apt -y update
sudo apt install -y nfs-common


sudo mkdir -p /mnt/share/tabshare
sudo mount ${FILESTORE_IP}:/tabshare /mnt/share/tabshare

# Set permissions (ToDo: set more restrictive permissions)
sudo chmod a+w /mnt/share/tabshare

sudo apt -y update
sudo apt install -y net-tools
apt install -y jq

sudo apt -y update
sudo apt -y install curl
sudo apt -y install ping
