#!/bin/sh

[ "$(uci -q get ipv6.config.enabled)" == "1" -a "$(uci -q get ipv6.config.mode)" == "native" ] && {
	i=1
	while [ $i -le 1 ];
	do
		if [ "$(ifstatus lan|jsonfilter -e '@["ipv6-prefix-assignment"][0].address')" == "" ];then
			sleep 120
			ifup -w wan6
		else
			break
		fi

		let i++
	done
}
