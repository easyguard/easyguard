#!/bin/bash

protectionLevel=$(jq --raw-output '.protectionLevel' dns.json)
case $protectionLevel in
	"normal")
		general="https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/multi.txt"
		;;
	"high")
		general="https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/pro.txt"
		;;
	"aggressive")
		general="https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/pro.plus.txt"
		;;
	*)
		echo "Invalid protection level selected"
		exit 1
		;;
esac

securityLinks=""

tif=$(jq --raw-output '.tif' dns.json)
badware=$(jq --raw-output '.badware' dns.json)
nrd=$(jq --raw-output '.nrd' dns.json)
extra=$(jq --raw-output '.extra' dns.json)

if [ "$tif" = "true" ]; then
	securityLinks="$securityLinks- https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/tif.txt
      "
fi
if [ "$badware" = "true" ]; then
	securityLinks="$securityLinks- https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/hoster.txt
      "
fi
if [ "$nrd" = "true" ]; then
	securityLinks="$securityLinks- https://raw.githubusercontent.com/xRuffKez/NRD/main/nrd-14day_wildcard.txt
      "
fi
# if [ "$extra" = "true" ]; then
# 	securityLinks="$securityLinks- |\n*.mov\n*.zip\n"
# fi

# CAUTION - This requires space indentation
cat <<EOF > /etc/blocky/config.yml
upstream:
  default:
    - https://dns.digitale-gesellschaft.ch/dns-query
blocking:
  blackLists:
    general:
      - $general
    security:
      $securityLinks
    child:
      - https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/gambling.txt
      - https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/nosafesearch.txt
      - https://nsfw.oisd.nl/domainswild
  clientGroupsBlock:
    default:
      - general
      - security
ports:
  dns: 53
EOF

rc-service blocky restart