#!/bin/sh

i=0

while [ $i -lt 5 ]
do
	sleep 180
	#ping -w 10 -c 10 114.114.114.114
	if [ "$(uci -q get jd_product.network.connected)" = "1" ] ; then
		break
	else
		/etc/init.d/network wan_reconn
		sleep 60
		#/etc/init.d/firewall restart
		logger "jd_boot_net_detect.sh: wan_reconn $i"
	fi
	let i++
done
