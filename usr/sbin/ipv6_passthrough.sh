#!/bin/sh

wan_name="$(uci -q get network.wan.ifname)"
[ -z "$wan_name" ] && wan_name='eth4'

if [ "$(uci -q get ipv6.config.enabled)" = "1" -a "$(uci -q get ipv6.config.mode)" = "relay" -a "$(uci -q get system.@system[0].apmode_init)" = "0" ]; then
	jd_domain_acl.sh add

	if [ -n "$1" ];then
		if [ "$1" = "restart" -o "$1" = "wan_reconn" ];then
			/etc/init.d/network "$1"
			if [ "$wan_name" = "ath02" -o "$wan_name" = "ath12" -o "$wan_name" = "ath22" ];then
				sleep 40
			else
				sleep 10
			fi
			ebtables -t broute -F IPv6_Bridge 2>/dev/null
			ebtables -t broute -D BROUTING -j IPv6_Bridge 2>/dev/null
			ebtables -t broute -X IPv6_Bridge 2>/dev/null
			for line in `ip6tables -w -t nat -nvL PREROUTING --line-number | grep -w REDIRECT | grep -w udp | grep -w 53 | awk '{print $1}' | sort -nr`
			do
				ip6tables -w -t nat -D PREROUTING $line 2>/dev/null
			done
			brctl delif br-lan "$wan_name" 2>/dev/null
		elif [ "$1" = "clear_config" ];then
			ebtables -t broute -F IPv6_Bridge 2>/dev/null
			ebtables -t broute -D BROUTING -j IPv6_Bridge 2>/dev/null
			ebtables -t broute -X IPv6_Bridge 2>/dev/null
			for line in `ip6tables -w -t nat -nvL PREROUTING --line-number | grep -w REDIRECT | grep -w udp | grep -w 53 | awk '{print $1}' | sort -nr`
			do
				ip6tables -w -t nat -D PREROUTING $line 2>/dev/null
			done
			brctl delif br-lan "$wan_name" 2>/dev/null
			return
		fi
	fi
else
	[ "$(uci -q get system.@system[0].apmode_init)" != "1" ] && {
		jd_domain_acl.sh del
	}

	if [ -n "$1" ]; then
		if [ "$1" = "restart" -o "$1" = "wan_reconn" ];then
			/etc/init.d/network "$1"
			ebtables -t broute -F IPv6_Bridge 2>/dev/null
			ebtables -t broute -D BROUTING -j IPv6_Bridge 2>/dev/null
			ebtables -t broute -X IPv6_Bridge 2>/dev/null
		elif [ "$1" = "clear_config" ];then
			ebtables -t broute -F IPv6_Bridge 2>/dev/null
			ebtables -t broute -D BROUTING -j IPv6_Bridge 2>/dev/null
			ebtables -t broute -X IPv6_Bridge 2>/dev/null
			return
		fi
	fi
fi

[ "$(uci -q get ipv6.config.enabled)" = "1" -a "$(uci -q get ipv6.config.mode)" = "relay" ] && {
	if [ "$(uci -q get system.@system[0].apmode_init)" = "0" ]; then
		ebtables -t broute -N IPv6_Bridge
		ebtables -t broute -I BROUTING -j IPv6_Bridge
		ebtables -t broute -A IPv6_Bridge -p ! ipv6 -j DROP -i "$wan_name"
		#ebtables -t broute -A IPv6_Bridge -p ipv6 --ip6-proto udp --ip6-dport 53 -j redirect

		ip6tables -t nat -I PREROUTING -p udp -m udp --dport 53 -m string --hex-string "|0b|jdcloudwifi|03|com|" --algo bm --to 65535 --icase -j REDIRECT --to-ports 53

		brctl addif br-lan "$wan_name"
	fi
}
