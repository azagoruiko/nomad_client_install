#!/usr/bin/bash

echo "Installing NFS client..."
apt-get install -y nfs-common

echo "Creating shared folder..."
mkdir /var/nfs
chmod 777 /var/nfs

echo "mounting nfs share..."
mount 192.168.0.10:/var/nfs_share/ /var/nfs

echo "Downloading nomad..."
NOMAD_VERSION="0.8.4"
curl --silent --remote-name https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip
curl --silent --remote-name https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS
curl --silent --remote-name https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS.sig

echo "Installing nomad..."
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
cat nomad_files/nomad.service > /etc/systemd/system/nomad.service

echo "Configuring nomad as client..."
mkdir --parents /etc/nomad.d
touch /etc/nomad.d/nomad.hcl
chmod 640 /etc/nomad.d/nomad.hcl
cat nomad_files/nomad.hcl > /etc/nomad.d/nomad.hcl

echo "Enabling client..."
sudo chmod 640 /etc/nomad.d/client.hcl
cat nomad_files/client.hcl > /etc/nomad.d/client.hcl
sudo chown --recursive nomad:nomad /etc/nomad.d

echo "Starting nomad service..."
systemctl enable nomad
systemctl start nomad
systemctl status nomad

#Assume that docker already installed and the user exists
#sudo groupadd docker

#Add myself to docker group
usermod -aG docker $USER

#Add nomad to docker group
usermod -aG docker $USER
