#!/usr/bin/env bash

echo "Downloading Consul..."
CONSUL_VERSION="1.2.0"
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS.sig

echo "Installing Consul..."
apt-get install -y unzip
unzip consul_${CONSUL_VERSION}_linux_amd64.zip
chown root:root consul
mv consul /usr/local/bin/
consul --version

consul -autocomplete-install
complete -C /usr/local/bin/consul consul

echo "Configuring users..."
useradd --system --home /etc/consul.d --shell /bin/false consul
mkdir --parents /opt/consul
chown --recursive consul:consul /opt/consul

echo "Configuting systemd..."
cat consul_files/consul.service > /etc/systemd/system/consul.service

echo "Configuring Consul..."
mkdir --parents /etc/consul.d
cat consul_files/consul.hcl > /etc/consul.d/consul.hcl
chown --recursive consul:consul /etc/consul.d
chmod 640 /etc/consul.d/consul.hcl

if [ "$1" = "-server" ]
then
    cat consul_files/server.hcl > /etc/consul.d/server.hcl
    chown --recursive consul:consul /etc/consul.d
    chmod 640 /etc/consul.d/server.hcl
fi

echo "Starting Consul..."
systemctl enable consul
systemctl start consul
systemctl status consul