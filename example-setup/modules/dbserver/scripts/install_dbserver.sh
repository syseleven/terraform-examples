#!/bin/bash
# 2016 j.peschke@syseleven.de

# wait for a valid network configuration
echo "# Waiting for valid network configuration"
until ping -c 1 syseleven.de; do sleep 1; done

echo "# Install dependencies"
export DEBIAN_FRONTEND=noninteractive
apt-get update
## Install Percona for mysql
apt-get install -y curl
curl -O https://repo.percona.com/apt/percona-release_latest.generic_all.deb
apt-get install -y gnupg2 lsb-release ./percona-release_latest.generic_all.deb
apt-get update
percona-release setup pdpxc-84-lts
apt-get install -y percona-xtradb-cluster percona-haproxy

systemctl start mysql

# implement consul health check
cat <<EOF> /etc/consul.d/dbserver_health.json
{
  "service": {
    "name": "dbserver",
    "port": 80,
    "tags": ["mysql", "database"],
    "check": {
      "script": "ps aux |grep mysql > /dev/null",
      "interval": "10s"
    }
  }
}
EOF

systemctl restart consul

logger "# Finished dbserver installation"
echo "# Finished dbserver installation"

