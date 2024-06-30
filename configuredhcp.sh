#!/bin/bash

set -e # Exit on error

domainName=$(jq --raw-output 'if .domainName? then .domainName else "lan" end' dhcp.json)
dnsServers=$(jq --raw-output 'if .dnsServers? then .dnsServers else "10.10.99.1" end' dhcp.json)
defaultLeaseTime=$(jq --raw-output 'if .defaultLeaseTime? then .defaultLeaseTime else 600 end' dhcp.json)
maxLeaseTime=$(jq --raw-output 'if .maxLeaseTime? then .maxLeaseTime else 7200 end' dhcp.json)

ip=$(jq --raw-output 'if .lan?.ip? then .lan.ip else "10.10.99.1" end' networking.json)
subnet=$(jq --raw-output 'if .lan?.subnet? then .lan.subnet else "10.10.99.0" end' networking.json)
netmask=$(jq --raw-output 'if .lan?.netmask? then .lan.netmask else "255.255.255.0" end' networking.json)
dhcpFrom=$(jq --raw-output 'if .lan?.dhcpFrom? then .lan.dhcpFrom else "10.10.99.100" end' networking.json)
dhcpTo=$(jq --raw-output 'if .lan?.dhcpTo? then .lan.dhcpTo else "10.10.99.200" end' networking.json)

cat <<EOF > /etc/dhcp/dhcpd.conf
option domain-name "$domainName";
option domain-name-servers $dnsServers;

default-lease-time $defaultLeaseTime;
max-lease-time $maxLeaseTime;

authoritative;

subnet $subnet netmask $netmask {
	range $dhcpFrom $dhcpTo;
	option routers $ip;
}
EOF

rc-service dhcpd restart