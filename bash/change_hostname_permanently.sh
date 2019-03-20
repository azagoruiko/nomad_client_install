#!/usr/bin/env bash

cp /etc/cloud/cloud.cfg /etc/cloud/cloud.cfg.backup
cat /etc/cloud/cloud.cfg.backup | sed "s/preserve_hostname: false/preserve_hostname: true/g" > /etc/cloud/cloud.cfg

hostnamectl set-hostname $1