#!/bin/bash

set -e # Exit on error

WAN=$(jq --raw-output '.["wan"]' hardware.json)
LAN=$(jq --raw-output '.["lan"]' hardware.json)
WLAN=$(jq --raw-output '.["wlan"]' hardware.json)

outgoing=$(jq --raw-output '.ports?.outgoing?.[] | .ports.[] | "\(.protocol) dport \(.port) accept"' firewall.json)

cat <<EOF > /etc/nftables.nft
#!/usr/sbin/nft -f

flush ruleset

define BOGONS4 = { 0.0.0.0/8, 10.0.0.0/8, 10.64.0.0/10, 127.0.0.0/8, 127.0.53.53, 169.254.0.0/16, 172.16.0.0/12, 192.0.0.0/24, 192.0.2.0/24, 192.168.0.0/16, 198.18.0.0/15, 198.51.100.0/24, 203.0.113.0/24, 224.0.0.0/4, 240.0.0.0/4, 255.255.255.255/32 }

table inet filter {
	chain inbound_world {
		# INTERNET => FIREWALL
		icmp type echo-request limit rate 5/second accept
	}
	chain inbound_private {
		# INTERNAL => FIREWALL
		tcp dport 80 accept
		tcp dport 443 accept
		tcp dport 22 accept;
		udp dport 53 accept
		udp dport 67 accept
		tcp dport 3000 accept
	}
	chain inbound {
		# Default Deny
		type filter hook input priority 0; policy drop;
		# Allow established and related connections: Allows Internet servers to respond to requests from our Internal network
		ct state vmap { established : accept, related : accept, invalid : drop} counter

		# Drop obviously spoofed loopback traffic
		iifname "lo" ip daddr != 127.0.0.0/8 drop

		# Separate rules for traffic from Internet and from the internal network
		iifname lo accept
		iifname $WAN jump inbound_world
		iifname $LAN jump inbound_private
	}
	chain forward_private {
		# INTERNAL => INTERNET
		icmp type echo-request limit rate 5/second accept
$outgoing
	}
	# Rules for sending traffic from one network interface to another
	chain forward {
		# Default deny, again
		type filter hook forward priority 0; policy drop;
		# Accept established and related traffic
		ct state vmap { established : accept, related : accept, invalid : drop }
		# Let traffic from this router and from the Internal network get out onto the Internet
		iifname lo accept
		iifname $WLAN oifname $LAN accept
		# iifname $LAN accept
		iifname $LAN jump forward_private
		# Only allow specific inbound traffic from the Internet (only relevant if we present services to the Internet).
		# tcp dport { \$PORTFORWARDS } counter
	}
}

table nat {
	chain prerouting {
		type nat hook prerouting priority dstnat;
		# iifname $WAN tcp dport { \$PORTFORWARDS } dnat to 10.199.200.1
	}

	chain postrouting {
		type nat hook postrouting priority srcnat;
		policy accept;
		oif $WAN masquerade;
	}
}
EOF

nft -f /etc/nftables.nft