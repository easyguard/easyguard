#!/bin/bash
cd /etc/easyguard
git pull

rc-service easyguardapi stop
rc-service lighttpd stop

rm /etc/easyguard-web -r
wget https://github.com/easyguard/easyguard-web/releases/latest/download/web.tar.gz -O /etc/easyguard-web/web.tar.gz
tar -xvf /etc/easyguard-web/web.tar.gz -C /etc/easyguard-web
rm /etc/easyguard-web/web.tar.gz

get_architecture() {
	arch=$(uname -m)
	case $arch in
		x86_64) echo "x86_64" ;;
		aarch64) echo "aarch64" ;;
		*) echo "Unsupported architecture: $arch" ;;
	esac
}

arch=$(get_architecture)
echo Your architecture is $arch

wget https://github.com/easyguard/ezg-api/releases/latest/download/$arch-unknown-linux-musl -O /etc/easyguard-api
chmod +x /etc/easyguard-api

echo Rerunning EasyGuard setup
bash ./ezgsetup.sh

less /etc/easyguard/CHANGELOG