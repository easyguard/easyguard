#!/bin/bash

echo ' _____                 ____                     _ '
echo '| ____|__ _ ___ _   _ / ___|_   _  __ _ _ __ __| |'
echo '|  _| / _` / __| | | | |  _| | | |/ _` |  __/ _` |'
echo '| |__| (_| \__ \ |_| | |_| | |_| | (_| | | | (_| |'
echo '|_____\__,_|___/\__, |\____|\__,_|\__,_|_|  \__,_|'
echo '     [BETA]     |___/             SETUP'
echo !!! This is beta software, do not use in production !!!

set -e # Exit on error

WAN=$(jq --raw-output '.["wan"]' hardware.json)
LAN=$(jq --raw-output '.["lan"]' hardware.json)
WLAN=$(jq --raw-output '.["wlan"]' hardware.json)

export SPINNER_TEXT="Updating repositories"
./spinner.sh apk update

export SPINNER_TEXT="Installing bridge"
./spinner.sh apk add bridge
export SPINNER_TEXT="Installing hostapd"
./spinner.sh apk add hostapd
export SPINNER_TEXT="Installing wireless-tools"
./spinner.sh apk add wireless-tools
export SPINNER_TEXT="Installing wpa_supplicant"
./spinner.sh apk add wpa_supplicant

echo net.ipv4.ip_forward=1 > /etc/sysctl.conf
echo net.ipv6.conf.all.forwarding=1 >> /etc/sysctl.conf

sysctl -p

echo auto $WAN > /etc/network/interfaces
echo iface $WAN inet dhcp >> /etc/network/interfaces

echo auto $LAN >> /etc/network/interfaces
echo iface $LAN inet static >> /etc/network/interfaces
echo 	address 10.10.99.1/24 >> /etc/network/interfaces

rc-service networking restart

export SPINNER_TEXT="Installing nftables"
./spinner.sh apk add nftables
./spinner.sh rc-update add nftables

chmod +x configurenftables.sh
./configurenftables.sh

rc-service nftables start
nft -f /etc/nftables.nft

export SPINNER_TEXT="Installing DHCP Server"
./spinner.sh apk add dhcp
./spinner.sh rc-update add dhcpd

chmod +x configuredhcp.sh
./configuredhcp.sh

rc-service dhcpd start

cat <<EOF > /etc/hostapd/hostapd.conf
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
interface=wlan0
driver=nl80211
logger_syslog=-1
logger_syslog_level=2
logger_stdout=-1
logger_stdout_level=2
ssid=EasyGuard
hw_mode=g
channel=6
max_num_sta=32
rts_threshold=2347
fragm_threshold=2346
macaddr_acl=0
auth_algs=3
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=easyguard
wpa_key_mgmt=WPA-PSK WPA-PSK-SHA256
wpa_pairwise=TKIP CCMP
EOF

# rc-update add hostapd
# rc-service hostapd start

echo Configuring Web Interface
apk add lighttpd lighttpd-mod_auth
cat <<EOF > /etc/lighttpd/lighttpd.conf
var.basedir = "/etc/easyguard-web"
var.logdir = "/var/log/lighttpd"
var.statedir = "/var/lib/lighttpd"
server.modules = (
	"mod_access",
	"mod_accesslog",
	"mod_auth",
	"mod_authn_file"
)
include "mime-types.conf"
server.username      = "lighttpd"                                                                                       
server.groupname     = "lighttpd"                                                                                       
                                                                               
server.document-root = var.basedir
server.pid-file      = "/run/lighttpd.pid"
server.errorlog      = var.logdir  + "/error.log"

index-file.names     = ("index.php", "index.html", "index.htm", "default.htm")

auth.backend = "htdigest"
auth.backend.htdigest.userfile = "/etc/lighttpd/lighttpd-htdigest.user"

auth.require = ( "/" =>
(
"method" => "digest",
"realm" => "EasyGuard",
"require" => "valid-user"
)
)
EOF

user=root
password=easyguard
realm=EasyGuard
hash=`echo -n "$user:$realm:$password" | md5sum | cut -b -32`

echo "$user:$realm:$hash" > /etc/lighttpd/lighttpd-htdigest.user

rc-service lighttpd restart
rc-update add lighttpd

echo Setting up EasyGuard API
cat <<EOF > /etc/init.d/easyguardapi
#!/sbin/openrc-run

name=easyguardapi
description="EasyGuard API"
supervisor=supervise-daemon
command="/etc/easyguard-api"

depend() {
	after net
}
EOF
chmod +x /etc/init.d/easyguardapi
rc-update add easyguardapi
rc-service easyguardapi start

lbu include /etc/init.d/easyguardapi

echo Setting up Heartbeat
echo "*	*	*	*	*	/etc/easyguard/heartbeat.sh" >> /etc/crontabs/root

echo Setting up DNS
apk add blocky

chmod +x configuredns.sh
./configuredns.sh

rc-update add blocky

lbu ci -d

echo ""
echo ""
echo EasyGuard setup complete!
echo !!! Please reboot your system to apply changes !!!
echo In case you are using a diskless setup, your changes have been saved
echo ""
echo "Default Settings (currently hardcoded):"
echo "WAN: $WAN (DHCP)"
echo "LAN: $LAN (10.10.99.1)"
echo You can get DHCP leases from the LAN interface
echo Web Interface: http://10.10.99.1 (root:easyguard)