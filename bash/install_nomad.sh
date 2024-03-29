#!/usr/bin/bash

SERVER_IP="10.8.0.1"
NODE_CLASS=${1}
CLIENT_IP=${2}
SKIP_SERVICES=${3}

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


echo "Downloading nomad..."
NOMAD_VERSION="1.1.0"
curl --silent --remote-name https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_${ARCH}.zip
curl --silent --remote-name https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS
curl --silent --remote-name https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS.sig

echo "Installing nomad..."
apt-get install -y unzip
unzip nomad_${NOMAD_VERSION}_linux_${ARCH}.zip
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
cat nomad_files/nomad.service | sed "s/{server}/${SERVER_IP}/g;s/{ip}/${CLIENT_IP}/g" > /etc/systemd/system/nomad.service

echo "Configuring nomad as client..."
mkdir --parents /etc/nomad.d
touch /etc/nomad.d/nomad.hcl
chmod 640 /etc/nomad.d/nomad.hcl
cat nomad_files/nomad.hcl | sed "s/{server}/${SERVER_IP}/g;s/{ip}/${CLIENT_IP}/g" > /etc/nomad.d/nomad.hcl


if [[ "$3" = "-server" ]]
then
    echo "Enabling server..."
    sudo chmod 640 /etc/nomad.d/server.hcl
    cat nomad_files/server.hcl | sed "s/{server}/${SERVER_IP}/g;s/{ip}/${CLIENT_IP}/g" > /etc/nomad.d/server.hcl
    sudo chown --recursive nomad:nomad /etc/nomad.d
fi

echo "Enabling client..."
sudo chmod 640 /etc/nomad.d/client.hcl
cat nomad_files/client.hcl | sed "s/{server}/${SERVER_IP}/g;s/{ip}/${CLIENT_IP}/g;s/{class}/${NODE_CLASS}/g" > /etc/nomad.d/client.hcl
sudo chown --recursive nomad:nomad /etc/nomad.d

echo "installing docker..."
if [[ $ARCH == amd* ]]
then
  apt install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  add-apt-repository "deb [arch=${ARCH}] https://download.docker.com/linux/ubuntu bionic stable"
  apt update

else
  # Add Docker's official GPG key:
  apt-get update
  apt-get install ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/raspbian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  # Set up Docker's APT repository:
  echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/raspbian \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
fi
apt install -y docker-ce docker-ce-cli

cp nomad_files/docker-registry.json /etc/docker/daemon.json

systemctl status docker


echo "Linking with docker..."
#Assume that docker already installed and the user exists
groupadd docker

#Add myself to docker group
usermod -aG docker $USER

#Add nomad to docker group
usermod -aG docker nomad

if [[ "$SKIP_SERVICES" = "--no-service" ]]
then
  echo "Skipping nomad as a service..."
else
  echo "Starting nomad service..."
  systemctl enable nomad
  systemctl start nomad
  systemctl status nomad
fi



