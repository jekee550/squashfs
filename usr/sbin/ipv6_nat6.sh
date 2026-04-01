#!/bin/sh

ipv6_nat6_init(){
	#uci set network.globals.ula_prefix="$(uci get network.globals.ula_prefix | sed -e "s/^./d/")"
	#uci commit network
	#/etc/init.d/network wan_reconn

	#uci set dhcp.lan.ra_default="1"
	#uci commit dhcp
	#/etc/init.d/odhcpd restart

	uci set $(uci show firewall | sed -n -e "/\.name='wan'$/s//.masq6=1/p" | sed -n -e "1p")
	uci commit firewall

	uci set $(uci show firewall | sed -n -e "/\.name='Allow-ICMPv6-Forward'$/s//.enabled=0/p" | sed -n -e "1p")
	uci commit firewall
}

generate_firewall_nat6(){
cat << "EOF" > /etc/firewall.nat6
# Masquerading nat6 firewall script
#
# Then you can configure in /etc/config/firewall per zone, ala where you have:
#   option masq 1
# Just drop this in beneath it:
#   option masq6 1
# For IPv6 privacy (temporary addresses used for outgoing), also add:
#   option masq6_privacy 1
#
# Hope it's useful!
#
# https://github.com/akatrevorjay/openwrt-masq6
# ~ trevorj <github@trevor.joynson.io>
 
set -eo pipefail
 
. /lib/functions.sh
. /lib/functions/network.sh
. /usr/share/libubox/jshn.sh
 
log() {
	logger -t nat6 -s "$@"
}
 
get_ula_prefix() {
	uci get network.globals.ula_prefix
}
 
validate_ula_prefix() {
	local ula_prefix="$1"
	if [ $(echo "$ula_prefix" | grep -c -E "^([0-9a-fA-F]{4}):([0-9a-fA-F]{0,4}):") -ne 1 ] ; then
		log "Fatal error: IPv6 ULA ula_prefix=\"$ula_prefix\" seems invalid. Please verify that a ula_prefix is set and valid."
		return 1
	fi
}
 
ip6t() {
	ip6tables "$@"
}
 
ip6t_add() {
	if ! ip6t -C "$@" &>/dev/null; then
		ip6t -I "$@"
	fi
}
 
nat6_init() {
	iptables-save -t nat \
	| sed -e "/\s[DS]NAT\s/d;/\sMASQUERADE$/d;/\sFULLCONENAT/d" \
	| ip6tables-restore -T nat
}
 
masq6_network() {
	# $config contains the ID of the current section
	local network_name="$1"
 
	local device
	network_get_device device "$network_name" || return 0
 
	local done_net_dev
	for done_net_dev in $DONE_NETWORK_DEVICES; do
		if [ "$done_net_dev" = "$device" ]; then
			log "Already configured device=\"$device\", so leaving as is."
			return 0
		fi
	done
 
	log "Found device=\"$device\" for network_name=\"$network_name\"."
 
	if [ $zone_masq6_privacy -eq 1 ]; then
		log "Enabling IPv6 temporary addresses for device=\"$device\"."
 
		log "Accepting router advertisements on $device even if forwarding is enabled (required for temporary addresses)"
		echo 2 > "/proc/sys/net/ipv6/conf/$device/accept_ra" \
		  || log "Error: Failed to change router advertisements accept policy on $device (required for temporary addresses)"
	fi
 
	append DONE_NETWORK_DEVICES "$device"
}
 
handle_zone() {
	# $config contains the ID of the current section
	local config="$1"
 
	local zone_name
	config_get zone_name "$config" name
 
	# Enable masquerading via NAT6
	local zone_masq6
	config_get_bool zone_masq6 "$config" masq6 0
 
	log "Firewall config=\"$config\" zone=\"$zone_name\" zone_masq6=\"$zone_masq6\"."
 
	if [ $zone_masq6 -eq 0 ]; then
		return 0
	fi
 
	# IPv6 privacy extensions: Use temporary addrs for outgoing connections?
	local zone_masq6_privacy
	config_get_bool zone_masq6_privacy "$config" masq6_privacy 1
 
	log "Found firewall zone_name=\"$zone_name\" with zone_masq6=\"$zone_masq6\" zone_masq6_privacy=\"$zone_masq6_privacy\"."
 
	log "Setting up masquerading nat6 for zone_name=\"$zone_name\" with zone_masq6_privacy=\"$zone_masq6_privacy\""
 
	local ula_prefix=$(get_ula_prefix)
	validate_ula_prefix "$ula_prefix" || return 1
 
	local postrouting_chain="zone_${zone_name}_postrouting"
	log "Ensuring ip6tables chain=\"$postrouting_chain\" contains our MASQUERADE."
	ip6t_add "$postrouting_chain" -t nat \
		-m comment --comment "!fw3" -j MASQUERADE
 
	local input_chain="zone_${zone_name}_input"
	log "Ensuring ip6tables chain=\"$input_chain\" contains our permissive DNAT rule."
	ip6t_add "$input_chain" -t filter -m conntrack --ctstate DNAT \
		-m comment --comment "!fw3: Accept port forwards" -j ACCEPT
 
	local forward_chain="zone_${zone_name}_forward"
	log "Ensuring ip6tables chain=\"$forward_chain\" contains our permissive DNAT rule."
	ip6t_add "$forward_chain" -t filter -m conntrack --ctstate DNAT \
		-m comment --comment "!fw3: Accept port forwards" -j ACCEPT
 
	local DONE_NETWORK_DEVICES=""
	config_list_foreach "$config" network masq6_network
 
	log "Done setting up nat6 for zone=\"$zone_name\" on devices: $DONE_NETWORK_DEVICES"
}
 
main() {
	nat6_init
	config_load firewall
	config_foreach handle_zone zone
}

echo 1 > /sys/kernel/debug/ecm/front_end_ipv6_stop

main "$@"
EOF
}

set_nat6_firewall(){
	uci -q delete firewall.nat6
	uci set firewall.nat6="include"
	uci set firewall.nat6.path="/etc/firewall.nat6"
	uci set firewall.nat6.reload="1"
	uci commit firewall
	#/etc/init.d/firewall restart
}

if [ $1 == "start" ]; then
	echo "start ipv6 nat6"
	ipv6_nat6_init
	generate_firewall_nat6
	set_nat6_firewall
	[ -z "$(cat /etc/sysupgrade.conf | grep "firewall.nat6")" ] && echo "/etc/firewall.nat6" >> /etc/sysupgrade.conf
elif [ $1 == "stop" ]; then
	echo "stop ipv6 nat6"
	uci set $(uci show firewall | sed -n -e "/\.name='wan'$/s//.masq6=0/p" | sed -n -e "1p")
	uci set $(uci show firewall | sed -n -e "/\.name='Allow-ICMPv6-Forward'$/s//.enabled=/p" | sed -n -e "1p")
	
	wan_interface=""

	proto="$(uci get network.wan.proto 2>/dev/null)"
	if [ "$proto" == "pppoe" ];then
		wan_interface="pppoe-wan"
	else
		wan_interface="$(uci get network.wan.ifname 2>/dev/null)"
	fi

	if [ -n "$wan_interface" ];then
		echo 1 > /proc/sys/net/ipv6/conf/$wan_interface/accept_ra
	fi

	rm -rf /etc/firewall.nat6 2>/dev/null
	uci -q delete firewall.nat6
	uci commit firewall
	#/etc/init.d/firewall restart

	echo 0 > /sys/kernel/debug/ecm/front_end_ipv6_stop
else
	echo "unknown type of command."
fi
