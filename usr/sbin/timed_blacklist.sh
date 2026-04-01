#!/bin/sh

. /lib/functions/wifi_access.sh

action=$1
mac=$2

#二层
ebt_del_rule() {
	local macaddr=$1

	ebtables -t filter -D forwardcontrol -s $macaddr -j DROP 2>/dev/null
	ebtables -t filter -D inputcontrol -s $macaddr -j DROP 2>/dev/null
}

ebt_add_rule() {
	local macaddr=$1

	ebtables -t filter -A forwardcontrol -s $macaddr -j DROP
	ebtables -t filter -A inputcontrol -s $macaddr -j DROP
}

allow_ebt_del_rule() {
	local macaddr=$1

	ebtables -t filter -D forwardcontrol -s $macaddr -j ACCEPT 2>/dev/null
	ebtables -t filter -D inputcontrol -s $macaddr -j ACCEPT 2>/dev/null
}

allow_ebt_add_rule() {
	local macaddr=$1

	ebtables -t filter -I forwardcontrol -s $macaddr -j ACCEPT
	ebtables -t filter -I inputcontrol -s $macaddr -j ACCEPT
}

#三层
ipt_del_rule() {                                                  
	local macaddr=$1

	iptables -t filter -D forwardcontrol -m mac --mac-source $macaddr -j DROP 2>/dev/null
	iptables -t filter -D inputcontrol -m mac --mac-source $macaddr -j DROP 2>/dev/null

	ip6tables -t filter -D forwardcontrol -m mac --mac-source $macaddr -j DROP 2>/dev/null
	ip6tables -t filter -D inputcontrol -m mac --mac-source $macaddr -j DROP 2>/dev/null
}

ipt_add_rule() {
	local macaddr=$1

	iptables -t filter -A forwardcontrol -m mac --mac-source $macaddr -j DROP
	iptables -t filter -A inputcontrol -m mac --mac-source $macaddr -j DROP

	ip6tables -t filter -A forwardcontrol -m mac --mac-source $macaddr -j DROP
	ip6tables -t filter -A inputcontrol -m mac --mac-source $macaddr -j DROP

	local section=$(echo $macaddr|tr 'a-z' 'A-Z'|tr -d ':')
	local ip=$(uci -q get jd_stainfo.$section.ip)
	[ -n "$ip" ] && echo "$ip" > /proc/net/nf_conntrack
	[ -n "$ip" ] && ip neigh flush $ip
}

allow_ipt_del_rule() {
	local macaddr=$1

	iptables -t filter -D forwardcontrol -m mac --mac-source $macaddr -j ACCEPT 2>/dev/null
	iptables -t filter -D inputcontrol -m mac --mac-source $macaddr -j ACCEPT 2>/dev/null

	ip6tables -t filter -D forwardcontrol -m mac --mac-source $macaddr -j ACCEPT 2>/dev/null
	ip6tables -t filter -D inputcontrol -m mac --mac-source $macaddr -j ACCEPT 2>/dev/null
}

allow_ipt_add_rule() {
	local macaddr=$1

	iptables -t filter -I forwardcontrol -m mac --mac-source $macaddr -j ACCEPT
	iptables -t filter -I inputcontrol -m mac --mac-source $macaddr -j ACCEPT

	ip6tables -t filter -I forwardcontrol -m mac --mac-source $macaddr -j ACCEPT
	ip6tables -t filter -I inputcontrol -m mac --mac-source $macaddr -j ACCEPT

	local section=$(echo $macaddr|tr 'a-z' 'A-Z'|tr -d ':')
	local ip=$(uci -q get jd_stainfo.$section.ip)
	[ -n "$ip" ] && echo "$ip" > /proc/net/nf_conntrack
	[ -n "$ip" ] && ip neigh flush $ip
}

mode=$(uci -q get jd_product.accesscontrol.mode)

if [ "$action" = "add" ];then
	#echo "$action $mac"

	if [ "$mode" = "allow" ]; then
		wifi_del_maclist $mac
		wifi_kick_user $mac

		allow_ipt_del_rule $mac
		allow_ebt_del_rule $mac
	else
		wifi_add_maclist $mac
		wifi_kick_user $mac

		ebt_del_rule $mac
		ebt_add_rule $mac
		ipt_del_rule $mac
		ipt_add_rule $mac
	fi

	section=$(echo $mac|tr 'a-z' 'A-Z'|tr -d ':')
	uci -q set jd_stainfo.$section.net_enable='0'
	uci commit jd_stainfo.$section
elif [ "$action" = "del" ];then
	#echo "$action $mac"

	if [ "$mode" = "allow" ]; then
		wifi_add_maclist $mac

		allow_ebt_del_rule $mac
		allow_ebt_add_rule $mac
		allow_ipt_del_rule $mac
		allow_ipt_add_rule $mac
	else
		wifi_del_maclist $mac

		ipt_del_rule $mac
		ebt_del_rule $mac
	fi

	section=$(echo $mac|tr 'a-z' 'A-Z'|tr -d ':')
	uci -q set jd_stainfo.$section.net_enable='1'
	uci commit jd_stainfo.$section
else
	echo "$action $mac"
fi
