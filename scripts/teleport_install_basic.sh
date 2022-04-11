#!/bin/bash

set -x

# Setup teleport proxy server config file
TELE_VERSION="8.3.4"

# Check teleport systemctl status
STATUS=$(systemctl is-active teleport.service)

if [[ $STATUS == 'active' ]]; then
	systemctl stop teleport.service
fi

# Setup teleport data dir used for transient storage
if [ -d /var/lib/teleport ]; then
	rm -fr /var/lib/teleport
fi
mkdir -p /var/lib/teleport/
chown -R root:adm /var/lib/teleport

# Setup teleport run dir for pid files
mkdir -p /var/run/teleport/
chown -R root:adm /var/run/teleport

# Download and install teleport
pushd /tmp || exit
curl -L --retry 100 --retry-delay 0 --connect-timeout 1 --max-time 300 -o teleport.tar.gz https://get.gravitational.com/teleport/${TELE_VERSION}/teleport-ent-v${TELE_VERSION}-linux-amd64-bin.tar.gz
tar -xzf /tmp/teleport.tar.gz
cp teleport-ent/tctl teleport-ent/tsh teleport-ent/teleport /usr/local/bin
rm -rf /tmp/teleport.tar.gz /tmp/teleport-ent
popd || return

# Example URL
sed -i s'/teleport.shipttech.com/teleport.gcp.shipttech.com/g' /etc/teleport.yaml

systemctl start teleport
