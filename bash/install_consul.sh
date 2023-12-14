#!/usr/bin/env bash

if [ -e $1 ]
then
    echo "parameters are like 192.168.0.21 -server"
    exit 1
fi

echo "Getting CPU arch"
ARCH=$(uname -m)
echo $ARCH

if [[ $ARCH == arm* || $ARCH == aarch* ]]
then
  echo "Arm!"
  if [[ $ARCH == "arm64" ||  $ARCH == "aarch64" ]]
  then
    ARCH="arm64"
  else
    ARCH="arm"
  fi
else
  echo "AMD!"
  ARCH="amd64"
fi
echo $ARCH

echo "Downloading Consul..."
CONSUL_VERSION="1.4.3"
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_${ARCH}.zip
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS.sig

echo "Installing Consul..."
apt-get install -y unzip
unzip consul_${CONSUL_VERSION}_linux_${ARCH}.zip
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
SERVER_ARGS=""
if [[ "$2" = "-server" ]]
then
    SERVER_ARGS=" -server "
fi
cat consul_files/consul.service | sed "s/{server}/${SERVER_ARGS}/g"> /etc/systemd/system/consul.service

echo "Configuring Consul..."
mkdir --parents /etc/consul.d
cat consul_files/consul.hcl  | sed "s/{server}/${2}/g;s/{ip}/${1}/g" > /etc/consul.d/consul.hcl
chown --recursive consul:consul /etc/consul.d
chmod 640 /etc/consul.d/consul.hcl

if [[ "$2" = "-server" ]]
then
    cat consul_files/server.hcl  | sed "s/{server}/${2}/g;s/{ip}/${1}/g" > /etc/consul.d/server.hcl
    chown --recursive consul:consul /etc/consul.d
    chmod 640 /etc/consul.d/server.hcl
fi

if [[ "$2" = "--no-service" ]]
then
  echo "Skipping nomad as a service..."
else
  echo "Starting Consul..."
  systemctl enable consul
  systemctl start consul
  systemctl restart consul
  systemctl status consul
fi
