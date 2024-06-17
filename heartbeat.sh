#!/bin/bash

url=$(jq -r ".url" /etc/easyguard/heartbeat.json)

curl $url