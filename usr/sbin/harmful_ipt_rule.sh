#!/bin/sh

t1_enable=$1
t2_enable=$2
t3_enable=$3
mac=$4

iptables -t nat -w -D heath_access_control -m mac --mac-source $mac -j internet_protect_one 2>/dev/null
iptables -t nat -w -D heath_access_control -m mac --mac-source $mac -j internet_protect_two 2>/dev/null
iptables -t nat -w -D heath_access_control -m mac --mac-source $mac -j internet_protect_three 2>/dev/null
iptables -t nat -w -D heath_access_control -m mac --mac-source $mac -p udp -m udp --dport 53 -j REDIRECT --to-ports 53 2>/dev/null

ip6tables -t nat -w -D heath_access_control -m mac --mac-source $mac -j internet_protect_one 2>/dev/null
ip6tables -t nat -w -D heath_access_control -m mac --mac-source $mac -j internet_protect_two 2>/dev/null
ip6tables -t nat -w -D heath_access_control -m mac --mac-source $mac -j internet_protect_three 2>/dev/null
ip6tables -t nat -w -D heath_access_control -m mac --mac-source $mac -p udp -m udp --dport 53 -j REDIRECT --to-ports 53 2>/dev/null

if [ "1" = "$t1_enable" -o "1" = "$t2_enable" -o "1" = "$t2_enable" ]; then
	iptables -t nat -w -A heath_access_control -m mac --mac-source $mac -p udp -m udp --dport 53 -j REDIRECT --to-ports 53
	ip6tables -t nat -w -A heath_access_control -m mac --mac-source $mac -p udp -m udp --dport 53 -j REDIRECT --to-ports 53
fi

if [ "1" = "$t1_enable" ]; then
	iptables -t nat -w -A heath_access_control -m mac --mac-source $mac -j internet_protect_one
	ip6tables -t nat -w -A heath_access_control -m mac --mac-source $mac -j internet_protect_one
fi

if [ "1" = "$t2_enable" ]; then
	iptables -t nat -w -A heath_access_control -m mac --mac-source $mac -j internet_protect_two
	ip6tables -t nat -w -A heath_access_control -m mac --mac-source $mac -j internet_protect_two
fi

if [ "1" = "$t3_enable" ]; then
	iptables -t nat -w -A heath_access_control -m mac --mac-source $mac -j internet_protect_three
	ip6tables -t nat -w -A heath_access_control -m mac --mac-source $mac -j internet_protect_three
fi

