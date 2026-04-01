#!/bin/sh

create_ipt_rule() {
	local ipt=$1
	local num="4"

	if [ "$ipt" = "iptables" ]; then
		num="4"
	else
		num="6"
	fi

	$ipt -t nat -w -N heath_access_control
	$ipt -t nat -F heath_access_control
	$ipt -t nat -w -I PREROUTING -i br-lan -j heath_access_control

	$ipt -t nat -w -N internet_protect_one
	$ipt -t nat -F internet_protect_one
	$ipt -t nat -w -A internet_protect_one -m set --match-set cat${num}1 dst,dst -p tcp -j REDIRECT --to-port 8081
	$ipt -t nat -w -A internet_protect_one -m set --match-set cat${num}s1 dst,dst -p tcp -j REDIRECT --to-port 4431
	
	$ipt -t nat -w -N internet_protect_two
	$ipt -t nat -F internet_protect_two
	$ipt -t nat -w -A internet_protect_two -m set --match-set cat${num}2 dst,dst -p tcp -j REDIRECT --to-port 8082
	$ipt -t nat -w -A internet_protect_two -m set --match-set cat${num}s2 dst,dst -p tcp -j REDIRECT --to-port 4432

	$ipt -t nat -w -N internet_protect_three
	$ipt -t nat -F internet_protect_three
	$ipt -t nat -w -A internet_protect_three -m set --match-set cat${num}3 dst,dst -p tcp -j REDIRECT --to-port 8083
	$ipt -t nat -w -A internet_protect_three -m set --match-set cat${num}s3 dst,dst -p tcp -j REDIRECT --to-port 4433
}

clear_ipt_rule(){
	local ipt=$1

	#删除
	$ipt -t nat -F internet_protect_one 2>/dev/null

	for line in `$ipt -w -t nat -nvL heath_access_control --line-number | grep -w internet_protect_one | awk '{print $1}' | sort -nr`
	do
		$ipt -w -t nat -D heath_access_control $line 2>/dev/null
	done

	#删除
	$ipt -t nat -F internet_protect_two 2>/dev/null

	for line in `$ipt -w -t nat -nvL heath_access_control --line-number | grep -w internet_protect_two | awk '{print $1}' | sort -nr`
	do
		$ipt -w -t nat -D heath_access_control $line 2>/dev/null
	done

	#删除
	$ipt -t nat -F internet_protect_three 2>/dev/null

	for line in `$ipt -w -t nat -nvL heath_access_control --line-number | grep -w internet_protect_three | awk '{print $1}' | sort -nr`
	do
		$ipt -w -t nat -D heath_access_control $line 2>/dev/null
	done

	$ipt -t nat -X internet_protect_one 2>/dev/null
	$ipt -t nat -X internet_protect_two 2>/dev/null
	$ipt -t nat -X internet_protect_three 2>/dev/null

	for line in `$ipt -w -t nat -nvL PREROUTING --line-number | grep -w heath_access_control | awk '{print $1}' | sort -nr`
	do
		$ipt -w -t nat -D PREROUTING $line 2>/dev/null
	done
	
	$ipt -t nat -F heath_access_control 2>/dev/null

	$ipt -t nat -X heath_access_control 2>/dev/null
}

create_ipset_rule() {
	local num=$1

	local suffix=""
	if [ "$num" = "6" ]; then
		suffix="family inet6"
	fi

	ipset -q create cat${num}1 hash:ip,port $suffix
	ipset -q create cat${num}2 hash:ip,port $suffix
	ipset -q create cat${num}3 hash:ip,port $suffix

	ipset -q create cat${num}s1 hash:ip,port $suffix
	ipset -q create cat${num}s2 hash:ip,port $suffix
	ipset -q create cat${num}s3 hash:ip,port $suffix
}

clear_ipset_rule() {
	local num=$1

	ipset -q destroy cat${num}1
	ipset -q destroy cat${num}2
	ipset -q destroy cat${num}3

	ipset -q destroy cat${num}s1
	ipset -q destroy cat${num}s2
	ipset -q destroy cat${num}s3
}

flush_ipset_rule() {
	local num=$1

	ipset -q flush cat${num}1
	ipset -q flush cat${num}2
	ipset -q flush cat${num}3

	ipset -q flush cat${num}s1
	ipset -q flush cat${num}s2
	ipset -q flush cat${num}s3
}

if [ "$1" = "addIpset" ]; then
	create_ipset_rule 4
	create_ipset_rule 6
elif [ "$1" = "addIptables" ]; then
	create_ipt_rule iptables
	create_ipt_rule ip6tables
elif [ "$1" = "delIpset" ]; then
        clear_ipset_rule 4
        clear_ipset_rule 6
elif [ "$1" = "delIptables" ]; then
	clear_ipt_rule iptables
	clear_ipt_rule ip6tables
elif [ "$1" = "flushIpset" ]; then
	flush_ipset_rule 4
	flush_ipset_rule 6
fi

