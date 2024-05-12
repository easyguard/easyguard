#!/bin/sh
# Installs EasyGuard Firewall

echo Updating repositories
apk update
echo Installing required packages
apk add git jq nodejs npm bash

echo Cloning EasyGuard repository
git clone https://github.com/cfpwastaken/easyguard /root/ezg
cd /root/ezg

echo Cloning EasyGuard-API repository
git clone https://github.com/cfpwastaken/easyguard-api /root/ezg-api

echo Running EasyGuard setup
bash ./ezgsetup.sh