#!/bin/sh

[ $(cat /tmp/sysinfo/product_name) != "RE-CS-06" ] && exit 0

sleep 10

ezmeshPID=$(ps | grep ezmesh-lan.conf | grep -v grep | awk '{print$1}')
if [ -n "$ezmeshPID" ]; then
	logger -t "hyfi-bridge-check" -p user.info -s "ezmesh process is running"

	hyctl_disabled=$(hyctl show | grep br-lan)
	hyctl_portType=$(hyctl show | grep Unknown)
	hyctl_ifname=$(hyctl show | grep Unknown | awk '{print $1}')

	if [ -n "$hyctl_disabled" ]; then
		if [ -n "$hyctl_portType" -a "$hyctl_ifname" != "ath01" ]; then
			logger -t "hyfi-bridge-check" -p user.info  -s "hyfi-bridge unknown port type"
			/etc/init.d/hyfi-bridging stop
			/etc/init.d/hyfi-bridging start
			/etc/init.d/ezmesh restart
		else
			logger -t "hyfi-bridge-check" -p user.info -s "hyfi-bridge are all ready"
		fi
	else
		logger -t "hyfi-bridge-check" -p user.info -s  "must first hyfi attach br-lan"
	fi
else
	logger -t "hyfi-bridge-check" -p user.info -s "ezmesh process is not running"
fi
