#!/bin/sh
# Installs EasyGuard Firewall

echo ' _____                 ____                     _ '
echo '| ____|__ _ ___ _   _ / ___|_   _  __ _ _ __ __| |'
echo '|  _| / _` / __| | | | |  _| | | |/ _` |  __/ _` |'
echo '| |__| (_| \__ \ |_| | |_| | |_| | (_| | | | (_| |'
echo '|_____\__,_|___/\__, |\____|\__,_|\__,_|_|  \__,_|'
echo '                |___/             INSTALLER'

echo Updating repositories
apk update
echo Installing required packages
apk add git jq bash curl

echo Cloning EasyGuard repository
mkdir /etc/easyguard
git clone https://github.com/cfpwastaken/easyguard /etc/easyguard
cd /etc/easyguard

echo Cloning EasyGuard-API repository
git clone https://github.com/cfpwastaken/easyguard-api /etc/easyguard-api

echo Cloning EasyGuard-Web repository
mkdir /etc/easyguard-web
git clone https://github.com/cfpwastaken/easyguard-web /etc/easyguard-web

echo Running EasyGuard setup
bash ./ezgsetup.sh