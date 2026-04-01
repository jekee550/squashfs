#!/bin/sh 
 
. /lib/functions.sh
 
config_load smartqos

aton()
{
        echo $1| awk '{c=256;split($0, ip, ".");print ip[4]+ip[3]*c+ip[2]*c^2+ip[1]*c^3}'
}

is_valid_net()
{
        ip=$1
        mask=$2
        gw=$3

        #ip&mask == gw&mask while is a valid net
        ipn=$(aton $ip)
        maskn=$(aton $mask)
        gwn=$(aton $gw)

        if [ $(($ipn & $maskn)) -ne $(($gwn & $maskn)) ];then
                return 1
        else
                return 0
        fi
}
 
handle_qos_rule() {         
    local ruleid="$1"

    config_get ruleip $ruleid ip
	
    local lan_netmask=$(uci get network.lan.netmask 2>/dev/null)
    local lan_ipaddr=$(uci get network.lan.ipaddr 2>/dev/null)

    #echo $ruleip $lan_netmask $lan_ipaddr
	
    is_valid_net $ruleip $lan_netmask $lan_ipaddr
    if [ $? -ne 0 ];then
	uci delete smartqos.$ruleid	
    fi

    #echo $ruleip
}
 
config_foreach handle_qos_rule rule

uci commit smartqos
