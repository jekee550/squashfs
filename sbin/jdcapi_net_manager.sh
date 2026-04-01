#!/bin/bash

is_valid_mac() {
    mac_address=$1
    if [[ $mac_address =~ ^([0-9A-Fa-f]{2}){6}$ ]]; then
        echo "Valid MAC address format"
    else
        exit 1
    fi
}

if [ $# -ne 2 ]; then
    echo "Usage: script.sh <MAC_ADDRESS> <TYPE>"
    exit 1
fi

is_valid_mac $1

if [ "$2" == "net_pause" ]; then
	logger -s "jdcapi_net_manager.sh: set $1 net pause stop"
        timeout 5 lua /usr/sbin/jdc_joylink_api.lua "{\"cmd\":\"net_manager_network_pause\",\"args\":{\"mac\":\"$1\",\"enable\":0,\"pause_time\":0}}"

elif [ "$2" == "temp_allow" ]; then
	logger -s "jdcapi_net_manager.sh: set $1 temp allow stop"
        timeout 5 lua /usr/sbin/jdc_joylink_api.lua "{\"cmd\":\"net_manager_network_allow\",\"args\":{\"mac\":\"$1\",\"enable\":0,\"allow_time\":0}}"
	
fi

