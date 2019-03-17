#!/usr/bin/bash

SERVER_IP="${1}"

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

echo "Setting up nomad as a service..."
cat nomad_files/nomad.service | sed "s/{server}/${2}/g;s/{ip}/${1}/g" > /etc/systemd/system/nomad.service

echo "Configuring nomad as client..."
mkdir --parents /etc/nomad.d
touch /etc/nomad.d/nomad.hcl
chmod 640 /etc/nomad.d/nomad.hcl
cat nomad_files/nomad.hcl | sed "s/{server}/${2}/g;s/{ip}/${1}/g" > /etc/nomad.d/nomad.hcl

echo "Enabling client..."
sudo chmod 640 /etc/nomad.d/client.hcl
cat nomad_files/client.hcl | sed "s/{server}/${2}/g;s/{ip}/${1}/g" > /etc/nomad.d/client.hcl
sudo chown --recursive nomad:nomad /etc/nomad.d

echo "installing docker..."
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt update
apt install -y docker-ce
systemctl status docker


echo "Linking with docker..."
#Assume that docker already installed and the user exists
#sudo groupadd docker

#Add myself to docker group
usermod -aG docker $USER

#Add nomad to docker group
usermod -aG docker nomad

echo "Starting nomad service..."
systemctl enable nomad
systemctl start nomad
systemctl status nomad



