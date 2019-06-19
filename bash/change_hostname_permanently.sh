#!/usr/bin/env bash

cp /etc/cloud/cloud.cfg /etc/cloud/cloud.cfg.backup
echo "preserve_hostname: true" > /etc/cloud/cloud.cfg

hostnamectl set-hostname $1

rm -r /opt/nomad
rm -r /opt/consul