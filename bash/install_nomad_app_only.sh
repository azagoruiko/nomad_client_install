#!/usr/bin/bash

echo "Downloading nomad..."
NOMAD_VERSION="0.8.4"
curl --silent --remote-name https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip
curl --silent --remote-name https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS
curl --silent --remote-name https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS.sig

echo "Installing nomad..."
apt-get install -y unzip
unzip nomad_${NOMAD_VERSION}_linux_amd64.zip
chown root:root nomad
mv nomad /usr/local/bin/
nomad --version

nomad -autocomplete-install
complete -C /usr/local/bin/nomad nomad

echo "Creating nomad user..."
useradd --system --home /etc/nomad.d --shell /bin/false nomad
mkdir --parents /opt/nomad
chown --recursive nomad:nomad /opt/nomad

echo "export NOMAD_ADDR=http://10.8.0.1:4646" >> ~/.bash_profile
