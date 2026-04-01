#!/bin/sh

. /lib/functions.sh

enable=$1
mode=$2
vid=$3
priority=$4
port=$5

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

if [ $enable -ne 0 -a $enable -ne 1 ]; then
	logger -t iptv "enable=$enable is wrong, please input(0-1)!!!"
	exit 0
fi

if [ $mode -ne 0 -a $mode -ne 1 ]; then
	logger -t iptv "mode=$mode is wrong, please input(0-1)!!!"
	exit 0
fi

if [ $vid -gt 4094 -o $vid -lt 1 ]; then
	logger -t iptv "vid=$vid is wrong, please input(1-4094)!!!"
	exit 0
fi

if [ $priority -gt 7 -o $priority -lt 0 ]; then
        logger -t iptv "priority=$priority is wrong, please input(0-7)!!!"
        exit 0
fi

if [ $port -gt 5 -o $port -lt 1 ]; then
	logger -t iptv "port=$port is wrong, please input(1-4)!!!"
	exit 0
fi

uci set jd_product.iptv_info.enable=$enable
uci set jd_product.iptv_info.mode=$mode
uci set jd_product.iptv_info.vid=$vid
uci set jd_product.iptv_info.priority=$priority
uci set jd_product.iptv_info.port=$port
uci commit jd_product

iptv_bridge_mac_clone_check() {
	local macaddr=$(uci -q get network.wan.macaddr)
	local origin_macaddr=$(uci -q get network.wan.origin_macaddr)

	if [ "$macaddr" != "" -a "$origin_macaddr" != "" ]; then
		[ "$macaddr" != "$origin_macaddr" ] && {
			uci -q set network.internet.macaddr="$macaddr"
			uci commit network
		}
	fi
}

if [ "$enable" = "1" ]; then
	if [ "$mode" = "0" ]; then
		#桥接模式
		uci -q del firewall.iptv
		uci -q del firewall.iptv_igmp
		uci -q del firewall.iptv_forward
		uci commit firewall

		uci -q del network.iptv

		if [ "$dev_type" = "RE-SS-02" ];then
			if [ "$(uci -q get network.wan.customize_wan)" = "eth0" ];then
				uci set network.lan.ifname='eth1 eth2 eth3 eth4'
				uci set network.wan.ifname='eth0'
			else
				uci set network.lan.ifname='eth0 eth1 eth2 eth3'
				uci set network.wan.ifname='eth4'
			fi
		else
			uci set network.lan.ifname='eth1 eth2 eth3'
			uci set network.wan.ifname='eth4'
		fi

		uci -q del network.internet

		uci commit network

		uci set firewall.iptv="zone"
		uci set firewall.iptv.name="internet"
		uci add_list firewall.iptv.network="internet"
		uci set firewall.iptv.input="ACCEPT"
		uci set firewall.iptv.output="ACCEPT"
		uci set firewall.iptv.forward="ACCEPT"

		uci set firewall.iptv_forward="forwarding"
		uci set firewall.iptv_forward.src="internet"
		uci set firewall.iptv_forward.dest="wan"

		uci reorder firewall.iptv=2
		uci reorder firewall.iptv_forward=4
		uci commit firewall
		
		case "$port" in
		"1")
			uci set network.internet="interface"
			uci set network.internet.type="bridge"

			uci set network.wan.ifname="br-internet"
			if [ "$dev_type" = "RE-SS-02" ];then
				if [ "$(uci -q get network.wan.customize_wan)" != "eth0" ];then
					uci set network.internet.ifname="eth4 eth0"
					uci set network.lan.ifname="eth1 eth2 eth3"
				fi
			else
				uci set network.internet.ifname="eth4 eth1"
				uci set network.lan.ifname="eth2 eth3"
			fi

			uci commit network
		;;
		"2")
			uci set network.internet="interface"
			uci set network.internet.type="bridge"

			uci set network.wan.ifname="br-internet"
			if [ "$dev_type" = "RE-SS-02" ];then
				if [ "$(uci -q get network.wan.customize_wan)" = "eth0" ];then
					uci set network.internet.ifname="eth0 eth1"
					uci set network.lan.ifname="eth2 eth3 eth4"
				else
					uci set network.internet.ifname="eth4 eth1"
					uci set network.lan.ifname="eth0 eth2 eth3"
				fi
			else
				uci set network.internet.ifname="eth4 eth2"
				uci set network.lan.ifname="eth1 eth3"
			fi

			uci commit network
		;;
		"3")
			uci set network.internet="interface"
			uci set network.internet.type="bridge"

			uci set network.wan.ifname="br-internet"
			if [ "$dev_type" = "RE-SS-02" ];then
				if [ "$(uci -q get network.wan.customize_wan)" = "eth0" ];then
					uci set network.internet.ifname="eth0 eth2"
					uci set network.lan.ifname="eth1 eth3 eth4"
				else
					uci set network.internet.ifname="eth4 eth2"
					uci set network.lan.ifname="eth0 eth1 eth3"
				fi
			else
				uci set network.internet.ifname="eth4 eth3"
				uci set network.lan.ifname="eth1 eth2"
			fi

			uci commit network
		;;
		"4")
			uci set network.internet="interface"
			uci set network.internet.type="bridge"

			uci set network.wan.ifname="br-internet"

			if [ "$(uci -q get network.wan.customize_wan)" = "eth0" ];then
				uci set network.internet.ifname="eth0 eth3"
				uci set network.lan.ifname="eth1 eth2 eth4"
			else
				uci set network.internet.ifname="eth4 eth3"
				uci set network.lan.ifname="eth0 eth1 eth2"
			fi

			uci commit network
		;;
		"5")
			uci set network.internet="interface"
			uci set network.internet.type="bridge"

			uci set network.wan.ifname="br-internet"

			if [ "$(uci -q get network.wan.customize_wan)" = "eth0" ];then
				uci set network.internet.ifname="eth0 eth4"
				uci set network.lan.ifname="eth1 eth2 eth3"
			fi
			uci commit network
		;;
		esac

		uci set network.internet.multicast_querier="0"
		uci set network.internet.igmp_snooping="0"
		uci commit network.internet
		iptv_bridge_mac_clone_check

		/etc/init.d/network light_reload &
	elif [ "$mode" = "1" ]; then
		#自定义模式
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

		uci set firewall.iptv="zone"
		uci set firewall.iptv.name="iptv"
		uci add_list firewall.iptv.network="iptv"
		uci set firewall.iptv.input="ACCEPT"
		uci set firewall.iptv.output="ACCEPT"
		uci set firewall.iptv.forward="ACCEPT"

		uci set firewall.iptv_igmp="rule"
		uci set firewall.iptv_igmp.name="Allow-IPTV-IGMP"
		uci set firewall.iptv_igmp.src="iptv"
		uci set firewall.iptv_igmp.proto="igmp"
		uci set firewall.iptv_igmp.family="ipv4"
		uci set firewall.iptv_igmp.target="ACCEPT"

		uci commit firewall

		case "$port" in
		"1")
			uci set network.iptv="interface"
			uci set network.iptv.force_link="1"
			uci set network.iptv.type="bridge"

			if [ "$dev_type" = "RE-SS-02" ];then
				if [ "$(uci -q get network.wan.customize_wan)" != "eth0" ];then
					uci set network.iptv.ifname="eth4.${vid} eth0"
					uci set network.lan.ifname='eth1 eth2 eth3'
				fi
			else
				uci set network.iptv.ifname="eth4.${vid} eth1"
				uci set network.lan.ifname='eth2 eth3'
			fi

			uci commit network
		;;
		"2")
			uci set network.iptv="interface"
			uci set network.iptv.force_link="1"
			uci set network.iptv.type="bridge"

			if [ "$dev_type" = "RE-SS-02" ];then
				if [ "$(uci -q get network.wan.customize_wan)" = "eth0" ];then
					uci set network.iptv.ifname="eth0.${vid} eth1"
					uci set network.lan.ifname='eth2 eth3 eth4'
				else
					uci set network.iptv.ifname="eth4.${vid} eth1"
					uci set network.lan.ifname='eth0 eth2 eth3'
				fi
			else
				uci set network.iptv.ifname="eth4.${vid} eth2"
				uci set network.lan.ifname='eth1 eth3'
			fi

			uci commit network
		;;
		"3")
			uci set network.iptv="interface"
			uci set network.iptv.force_link="1"
			uci set network.iptv.type="bridge"

			if [ "$dev_type" = "RE-SS-02" ];then
				if [ "$(uci -q get network.wan.customize_wan)" = "eth0" ];then
					uci set network.iptv.ifname="eth0.${vid} eth2"
					uci set network.lan.ifname='eth1 eth3 eth4'
				else
					uci set network.iptv.ifname="eth4.${vid} eth2"
					uci set network.lan.ifname='eth0 eth1 eth3'
				fi
			else
				uci set network.iptv.ifname="eth4.${vid} eth3"
				uci set network.lan.ifname='eth1 eth2'
			fi

			uci commit network
		;;
		"4")
			uci set network.iptv="interface"
			uci set network.iptv.force_link="1"
			uci set network.iptv.type="bridge"

			if [ "$(uci -q get network.wan.customize_wan)" = "eth0" ];then
				uci set network.iptv.ifname="eth0.${vid} eth3"
				uci set network.lan.ifname='eth1 eth2 eth4'
			else
				uci set network.iptv.ifname="eth4.${vid} eth3"
				uci set network.lan.ifname='eth0 eth1 eth2'
			fi

			uci commit network
		;;
		"5")
			uci set network.iptv="interface"
			uci set network.iptv.force_link="1"
			uci set network.iptv.type="bridge"

			if [ "$(uci -q get network.wan.customize_wan)" = "eth0" ];then
				uci set network.iptv.ifname="eth0.${vid} eth4"
				uci set network.lan.ifname='eth1 eth2 eth3'
			fi

			uci commit network
		;;
		esac

		uci set network.iptv.multicast_querier="0"
		uci set network.iptv.igmp_snooping="0"
		uci commit network.iptv

		/etc/init.d/network light_reload &
	fi
else
	uci -q del firewall.iptv
	uci -q del firewall.iptv_igmp
	uci -q del firewall.iptv_forward
	uci commit firewall

	uci -q del network.iptv

	if [ "$dev_type" = "RE-SS-02" ];then
		if [ "$(uci -q get network.wan.customize_wan)" = "eth0" ];then
			uci set network.lan.ifname='eth1 eth2 eth3 eth4'
			uci set network.wan.ifname='eth0'
		else
			uci set network.lan.ifname='eth0 eth1 eth2 eth3'
			uci set network.wan.ifname='eth4'
		fi
	else
		uci set network.lan.ifname='eth1 eth2 eth3'
		uci set network.wan.ifname='eth4'
	fi

	uci -q del network.internet

	uci commit network

	/etc/init.d/network light_reload &
fi

exit 0

