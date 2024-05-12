#!/bin/bash

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

echo "Done! Enjoj!"