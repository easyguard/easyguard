#!/bin/sh
# Installs EasyGuard Firewall

echo ' _____                 ____                     _ '
echo '| ____|__ _ ___ _   _ / ___|_   _  __ _ _ __ __| |'
echo '|  _| / _` / __| | | | |  _| | | |/ _` |  __/ _` |'
echo '| |__| (_| \__ \ |_| | |_| | |_| | (_| | | | (_| |'
echo '|_____\__,_|___/\__, |\____|\__,_|\__,_|_|  \__,_|'
echo '                |___/             INSTALLER'
echo Do not leave running unattended until Setup is started
echo as it will require user input

echo Updating repositories
apk update
echo Installing required packages
apk add git jq bash curl wget

echo Cloning EasyGuard repository
mkdir /etc/easyguard
git clone https://github.com/easyguard/easyguard /etc/easyguard
cd /etc/easyguard

echo Downloading EasyGuard API
#git clone https://github.com/cfpwastaken/easyguard-api /etc/easyguard-api

# ask arch from user
echo "Please enter your architecture (avail: x86_64, aarch64). Do not make a typo or it will not work!"
read arch
echo You have chosen $arch

wget https://github.com/easyguard/ezg-api/releases/latest/download/$arch-unknown-linux-musl -O /etc/easyguard-api

echo Downloading EasyGuard-Web
mkdir /etc/easyguard-web
#git clone https://github.com/cfpwastaken/easyguard-web /etc/easyguard-web

wget https://github.com/easyguard/easyguard-web/releases/latest/download/web.tar.gz -O /etc/easyguard-web/web.tar.gz
tar -xvf /etc/easyguard-web/web.tar.gz -C /etc/easyguard-web
rm /etc/easyguard-web/web.tar.gz

echo Running EasyGuard setup
bash ./ezgsetup.sh