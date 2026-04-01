#!/bin/sh
. /lib/functions.sh

is_iface_all_up=1

[ "$(uci -q get jdc_ezmesh.ezmesh.enable)" != "1" ] && exit 0
script_name=$(basename "$0")

# 查找并杀死同名进程
pids=$(pgrep -f "$script_name" | grep -v $$ |grep -v grep)
if [ -n "$pids" ]; then
	logger -s "jdc_ezmesh_chech_vap.sh : Killing existing processes...$pids"
    kill -9 $pids
fi

product_name=$(. /lib/ipq806x.sh && echo $(ipq806x_product_name)|tr -d '\n')


__check_one_iface_ready() {
	local config=$1
	local network mode disabled device dev_disabled

	config_get iface "$config" ifname
	config_get network "$config" network
	config_get mode "$config" mode
	config_get disabled "$config" disabled '0'

	# Skip this interface if disabled at the device level
	config_get device "$config" device
	config_get dev_disabled "$device" disabled '0'
	if [ "$dev_disabled" -gt 0 ]; then
		return
	fi

	if [ "$2" = "$network" -a "$disabled" -eq 0 -a "$mode" = "ap" ]; then
		# interface name may not be available
		if [ -z "$iface" ]; then
			is_iface_all_up=0
		else
			# interface may not be up
			iwconfig $iface 2>/dev/null |grep $iface
			retval=$?
			if [ $retval -ne 0 ] ;then
				logger -s "jdc_ezmesh_chech_vap.sh : interface $iface may not be up"
				is_iface_all_up=0
			fi
			# interface Encryption key is "too big"
			Encryption_key=$(iwconfig $iface 2>/dev/null |grep  "too big")
			if [ "$Encryption_key" != "" ] ;then
				logger -s "jdc_ezmesh_chech_vap.sh : interface $iface Encryption key is too big"
				is_iface_all_up=0
			fi
			# interface may not essid is empty
			if [ "$(repacdcli $iface get_essid)" = "" ] ;then
				logger -s "jdc_ezmesh_chech_vap.sh : interface $iface may not essid is empty"
				is_iface_all_up=0
			fi
			
			if [ $is_iface_all_up -eq 0 ];then
				if [ "$product_name" == "RE-CS-06" ];then
					/sbin/wifi multi_up $device $iface &
				else
					/sbin/wifi up $device $iface &
				fi
			fi
			
		fi
	fi
	return
}


__check_interfaces_ready () {
	config_load wireless

	is_iface_all_up=1
	config_foreach __check_one_iface_ready wifi-iface $1
}

sleep 180
__check_interfaces_ready lan
