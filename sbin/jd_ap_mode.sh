#!/bin/sh

. /lib/functions/ipv6.sh

#停用上网管家功能
set_net_manager_disable(){
	uci -q set role_group.global.switch_enable=0
	uci commit role_group
	rule_apply role_group reload
	rule_apply app_filter reload
	rule_apply mac_filter reload
	/usr/sbin/jdc_harm_rule.sh delIptables 2>/dev/null;/usr/sbin/jdc_harm_rule.sh delIpset 2>/dev/null
}

function start() {
	logger -s "jd_ap_mode.sh:start ap mode, stop router mode!"

	touch /tmp/.enter_ap_mode

	local mode=`uci -q get system.@system[0].apmode_init`
	if [ $mode == 1 ]
	then
		echo "-------current is ap mode, Do not repeat-----------"
		logger -s "jd_ap_mode.sh:current is ap mode, Do not repeat!"
		exit
	fi

	uci -q set system.@system[0].apmode_init=1
	uci -q set dhcp.lan.ignore=1

	/usr/sbin/iptv_vlan_clear.sh

	proto=`uci -q get network.lan.proto`

	uci -q set network.lan.proto='dhcp'
	uci -q set network.lan.proto_bak=$proto

	ifname=`uci -q get network.wan.ifname`
	uci -q set network.wan.ifname=''
	uci -q set network.wan.ifname_bak=$ifname

	[ -z "$(echo "$ifname"|grep eth)" ] && {
		uci -q set wireless.$ifname.disabled=1
	}

	product=`. /lib/ipq806x.sh && ipq806x_product_name`
	if [ "$product" == "RE-SS-02" ]
	then
		ap_mode_lan_if="eth1 eth2 eth3 eth4 eth0"
	else
		ap_mode_lan_if="eth1 eth2 eth3 eth4"
	fi
	
	uci -q set network.lan.ifname="$ap_mode_lan_if"

	jd_domain_acl.sh del
	jd_domain_acl.sh add

	local macaddr=$(uci -q get network.lan.macaddr)
	[ "" != "$macaddr" ] && {
		if [ "$product" == "RE-SS-02" ]; then
			uci set network.eth0='device'
			uci set network.eth0.name='eth0'
			uci set network.eth0.macaddr=$macaddr
		fi

		uci set network.eth1='device'
		uci set network.eth1.name='eth1'
		uci set network.eth1.macaddr=$macaddr

		uci set network.eth2='device'
		uci set network.eth2.name='eth2'
		uci set network.eth2.macaddr=$macaddr

		uci set network.eth3='devive'
		uci set network.eth3.name='eth3'
		uci set network.eth3.macaddr=$macaddr

		uci set network.eth4='device'
		uci set network.eth4.name='eth4'
		uci set network.eth4.macaddr=$macaddr
	}

	uci -q set network.wan.disabled='1'

	uci commit network
	uci commit wireless
	uci commit dhcp
	uci commit system

	#关闭随机mac和hostname
	/usr/sbin/jd_random_mac_and_hostname.sh 0
	
	ipv6_router_to_ap

	#将二层数据拦截到三层
	ebtables -t broute -D BROUTING -p ipv4 --ip-proto udp --ip-dport 53 -j redirect 2>/dev/null
	ebtables -t broute -D BROUTING -p ipv6 --ip6-proto udp --ip6-dport 53 -j redirect 2>/dev/null
	ebtables -t broute -D BROUTING -p ipv6 -j redirect 2>/dev/null

	for line in `iptables -w -t nat -nvL PREROUTING --line-number | grep -w REDIRECT | grep -w udp | grep -w 53 | awk '{print $1}' | sort -nr`
	do
		iptables -w -t nat -D PREROUTING $line 2>/dev/null
	done

	for line in `ip6tables -w -t nat -nvL PREROUTING --line-number | grep -w REDIRECT | grep -w udp | grep -w 53 | awk '{print $1}' | sort -nr`
	do
		ip6tables -w -t nat -D PREROUTING $line 2>/dev/null
	done

	iptables -t nat -I PREROUTING -p udp -m udp --dport 53 -m string --hex-string "|0b|jdcloudwifi|03|com|" --algo bm --to 65535 --icase -j REDIRECT --to-ports 53
	ip6tables -t nat -I PREROUTING -p udp -m udp --dport 53 -m string --hex-string "|0b|jdcloudwifi|03|com|" --algo bm --to 65535 --icase -j REDIRECT --to-ports 53
	#切换为ap模式关闭上网管家功能
	set_net_manager_disable
}

function stop() {
	logger -s "jd_ap_mode.sh:start router mode, stop ap mode!"

	local mode=`uci -q get system.@system[0].apmode_init`
	if [ $mode == 0 ]
	then
		echo "-------current is router mode, Do not repeat-----------"
		logger -s "jd_ap_mode.sh:current is router mode, Do not repeat!"
		exit
	fi

	uci -q set system.@system[0].apmode_init=0

	uci -q set dhcp.lan.ignore=0

	product=`. /lib/ipq806x.sh && ipq806x_product_name`
	if [ "$product" == "RE-SS-02" ]
	then
	    if [ "$(uci -q get network.wan.customize_wan)" = "eth0" ];then
		ap_router_lan_if="eth1 eth2 eth3 eth4"
	    else
		ap_router_lan_if="eth1 eth2 eth3 eth0"
	    fi
	else
		ap_router_lan_if="eth1 eth2 eth3"
	fi	
	uci -q set network.lan.ifname="$ap_router_lan_if"

	proto_bak=`uci -q get network.lan.proto_bak`
	[ -z "$proto_bak" ] && proto_bak='dhcp'
	uci -q set network.lan.proto=$proto_bak

	ifname=`uci -q get network.wan.ifname_bak`

	if [ -n "$ifname" ]
	then
		uci -q set network.wan.ifname=$ifname
		
		[ -z "$(echo "$ifname"|grep eth)" ] &&{
			uci -q set wireless.$ifname.disabled=0
		}
	else
		uci -q set network.wan.ifname='eth4'
	fi

	for line in `iptables -w -t nat -nvL PREROUTING --line-number | grep -w REDIRECT | grep -w udp | grep -w 53 | awk '{print $1}' | sort -nr`
	do
		iptables -w -t nat -D PREROUTING $line 2>/dev/null
	done

	for line in `ip6tables -w -t nat -nvL PREROUTING --line-number | grep -w REDIRECT | grep -w udp | grep -w 53 | awk '{print $1}' | sort -nr`
	do
		ip6tables -w -t nat -D PREROUTING $line 2>/dev/null
	done

	ebtables -t broute -D BROUTING -p ipv4 --ip-proto udp --ip-dport 53 -j redirect 2>/dev/null
	ebtables -t broute -D BROUTING -p ipv6 -j redirect 2>/dev/null
	ebtables -t broute -D BROUTING -p ipv6 --ip6-proto udp --ip6-dport 53 -j redirect 2>/dev/null

	jd_domain_acl.sh del

	uci delete network.eth4
	uci delete network.eth3
	uci delete network.eth2
	uci delete network.eth1
	uci delete network.eth0

	uci -q delete network.wan.disabled

	uci commit network
	uci commit wireless
	uci commit dhcp
	uci commit system

	ipv6_ap_to_router

	lanipaddr=$(uci -q get network.lan.ipaddr)
	[ -n "$lanipaddr" ] && echo "$lanipaddr" > /sys/kernel/debug/ecm/ecm_db/lan_info

	rm -rf /tmp/.enter_ap_mode
}

case "$1" in
	start )
		start
		;;
	stop )
		stop
		;;
	* )
		echo "****************"
		echo "no start or stop command"
		echo "****************"
		;;
esac
