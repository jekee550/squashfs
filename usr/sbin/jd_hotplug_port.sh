#!/bin/sh
# (C) 2024 jd.com

LINK=$1

logger -s "[jd_hotplug_port] : LINK=$LINK"

ifname=$(uci -q get network.wan.customize_wan)
[ -z "$ifname" ] && {
	ifname=$(uci -q get network.wan.ifname)
	[ -z "$ifname" ] && {
		ifname=$(uci -q get network.wan.device)
	}
}
# 如果WAN口为空，配置文件被破坏，退出
[ -z "$ifname" ] && exit 0

ifname_prefix=$(echo $ifname | cut -c 1-3)
logger -s "[jd_hotplug_port] : ifname=$ifname, ifname_prefix=$ifname_prefix"
# 如果WAN口不是eth开头，则不是有线物理口，不支持，退出
[ "$ifname_prefix" != "eth" ] && {
	product_name=$(uci -q get system.@system[0].product_name)
	[ "$product_name" = "Baili" -a "$ifname" = "lan0" ] || {
		logger -s "[jd_hotplug_port] : product_name=$product_name"
		exit 0
	}
}

if [ "$LINK" = "0" ]; then
	logger -s "[jd_hotplug_port] : $ifname down"
	uci set system.led_network.default=0
	uci set system.led_power.default=1
	uci set system.led_plugin.default=0
	#uci commit system
	uci set jd_product.network.connected='0'
	#uci commit jd_product
	/etc/init.d/led restart &
fi
