#!/bin/sh

. /lib/functions.sh

if [ -e /lib/ipq806x.sh ];then
        . /lib/ipq806x.sh
        dev_type="$(ipq806x_product_name)"
elif [ -e /lib/ramips.sh ];then
        . /lib/ramips.sh
        dev_type="$(ramips_product_name)"
else
        . /lib/functions.sh
        dev_type="$(product_name)"
fi

function iptv_close() {
	local enable=$(uci -q get jd_product.iptv_info.enable)
	if [ "$enable" == "1" ]; then
		uci -q del firewall.iptv
		uci -q del firewall.iptv_igmp
		uci -q del firewall.iptv_forward
		uci commit firewall

		uci -q del network.iptv

		if [ "$dev_type" = "RE-SS-02" ];then
			if [ "$(uci -q get network.wan.customize_wan)" = "eth0" ];then
				uci set network.lan.ifname='eth1 eth2 eth3 eth4'
			else
				uci set network.lan.ifname='eth0 eth1 eth2 eth3'
			fi
		else
			uci set network.lan.ifname='eth1 eth2 eth3'
		fi

		uci -q del network.internet

		if [ "$dev_type" = "RE-SS-02" ];then
			if [ "$(uci -q get network.wan.customize_wan)" = "eth0" ];then
				uci set network.wan.ifname='eth0'
			else
				uci set network.wan.ifname='eth4'
			fi
		else
			uci set network.wan.ifname='eth4'
		fi

		uci commit network

		uci -q set jd_product.iptv_info.enable="0"
		uci commit jd_product.iptv_info
	fi
}

iptv_close
