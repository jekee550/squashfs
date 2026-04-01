#!/bin/sh

. /lib/netifd/netifd-proto.sh

function ipv6_router_to_ap() {
	if [ "$(uci -q get ipv6.config.enabled)" = "1" ]; then
		uci -q set ipv6.bakconfig=config
		uci -q set ipv6.bakconfig.enabled=$(uci -q get ipv6.config.enabled)
		uci -q set ipv6.bakconfig.mode=$(uci -q get ipv6.config.mode)
		if [ "$(uci -q get ipv6.config.mode)" = "static" ]; then
			uci -q set ipv6.bakconfig.wan_ipaddr=$(uci -q get network.wan6.ip6addr)
			uci -q set ipv6.bakconfig.wan_gateway=$(uci -q get network.wan6.ip6gw)
			uci -q set ipv6.bakconfig.lan_prefix=$(uci -q get network.wan6.ip6prefix|awk -F '/' '{print $1}')
			uci -q set ipv6.bakconfig.lan_prefix_len=$(uci -q get network.wan6.ip6prefix|awk -F '/' '{print $2}')
		fi

		uci -q set ipv6.bakconfig.peerdns=$(uci -q get network.wan6.peerdns)
		uci -q set ipv6.bakconfig.dns1=$(uci -q get network.wan6.dns | awk -F ' ' '{print $1}')
		uci -q set ipv6.bakconfig.dns2=$(uci -q get network.wan6.dns | awk -F ' ' '{print $2}')
		uci -q set ipv6.bakconfig.fw_disable=$(uci -q get firewall.@defaults[0].disable_ipv6)

		uci commit ipv6

		ubus call jdcapi.static web_set_ipv6_relay '{"enabled":1, "type":"relay", "dns_enabled":0, "dns1":"", "dns2":"", "fw_enable":0}'
	else
		[ -e /usr/sbin/ipv6_passthrough.sh ] && /usr/sbin/ipv6_passthrough.sh clear_config

		uci -q set ipv6.bakconfig=config
		uci -q set ipv6.bakconfig.mode='off'
		uci -q set ipv6.bakconfig.enabled=$(uci -q get ipv6.config.enabled)
		uci -q set ipv6.bakconfig.fw_disable=$(uci -q get firewall.@defaults[0].disable_ipv6)

		uci commit ipv6

		ubus call jdcapi.static web_set_ipv6_relay '{"enabled":1, "type":"relay", "dns_enabled":0, "dns1":"", "dns2":"", "fw_enable":0}'
	fi
}

function ipv6_ap_to_router_proc() {
	if [ "$(uci -q get ipv6.bakconfig.mode)" = "native" -o "$(uci -q get ipv6.bakconfig.mode)" = "onlyrouter" ]; then
		peerdns=$(uci -q get ipv6.bakconfig.peerdns)
		if [ "$peerdns" = "0" ]; then
			dns1=$(uci -q get ipv6.bakconfig.dns1)
			dns2=$(uci -q get ipv6.bakconfig.dns2)
		fi

		fw_disable=$(uci -q get ipv6.bakconfig.fw_disable)

		json_init
		json_add_int enabled "$1"
		if [ "$(uci -q get ipv6.bakconfig.mode)" = "native" ]; then
			json_add_string type "native"
		else
			json_add_string type "onlyrouter"
		fi

		if [ "$peerdns" = "0" ]; then
			json_add_int dns_enabled "1"
			json_add_string dns1 "$dns1"
			json_add_string dns2 "$dns2"
		else
			json_add_int dns_enabled "0"
			json_add_string dns1 ""
			json_add_string dns2 ""
		fi

		if [ "$fw_disable" = "1" ]; then
			json_add_int fw_enable "0"
		else
			json_add_int fw_enable "1"
		fi

		json_close_object

		if [ "$(uci -q get ipv6.bakconfig.mode)" = "native" ]; then
			ubus call jdcapi.static web_set_ipv6_native "$(json_dump)"
		else
			ubus call jdcapi.static web_set_ipv6_onlyrouter "$(json_dump)"
		fi
	elif [ $(uci -q get ipv6.bakconfig.mode) = "nat6" ]; then
		peerdns=$(uci -q get ipv6.bakconfig.peerdns)
		if [ "$peerdns" = "0" ]; then
			dns1=$(uci -q get ipv6.bakconfig.dns1)
			dns2=$(uci -q get ipv6.bakconfig.dns2)
		fi

		json_init
		json_add_int enabled "$1"
		json_add_string type "nat6"
		if [ "$peerdns" = "0" ]; then
			json_add_int dns_enabled "1"
			json_add_string dns1 "$dns1"
			json_add_string dns2 "$dns2"
		else
			json_add_int dns_enabled "0"
			json_add_string dns1 ""
			json_add_string dns2 ""
		fi

		json_add_int fw_enable "1"

		json_close_object

		ubus call jdcapi.static web_set_ipv6_nat6 "$(json_dump)"
	elif [ $(uci -q get ipv6.bakconfig.mode) = "relay" ]; then
		peerdns=$(uci -q get ipv6.bakconfig.peerdns)
		if [ "$peerdns" = "0" ]; then
			dns1=$(uci -q get ipv6.bakconfig.dns1)
			dns2=$(uci -q get ipv6.bakconfig.dns2)
		fi

		fw_disable=$(uci -q get ipv6.bakconfig.fw_disable)

		json_init
		json_add_int enabled "$1"
		json_add_string type "relay"
		if [ "$peerdns" = "0" ]; then
			json_add_int dns_enabled "1"
			json_add_string dns1 "$dns1"
			json_add_string dns2 "$dns2"
		else
			json_add_int dns_enabled "0"
			json_add_string dns1 ""
			json_add_string dns2 ""
		fi

		if [ "$fw_disable" = "1" ]; then
			json_add_int fw_enable "0"
		else
			json_add_int fw_enable "1"
		fi

		json_close_object

		ubus call jdcapi.static web_set_ipv6_relay "$(json_dump)"
	elif [ $(uci -q get ipv6.bakconfig.mode) = "static" ]; then
		wan_ipaddr=$(uci -q get ipv6.bakconfig.wan_ipaddr)
		wan_gateway=$(uci -q get ipv6.bakconfig.wan_gateway)
		lan_prefix=$(uci -q get ipv6.bakconfig.lan_prefix)
		lan_prefix_len=$(uci -q get ipv6.bakconfig.lan_prefix_len)
		peerdns=$(uci -q get ipv6.bakconfig.peerdns)
		if [ "$peerdns" = "0" ]; then
			dns1=$(uci -q get ipv6.bakconfig.dns1)
			dns2=$(uci -q get ipv6.bakconfig.dns2)
		fi

		fw_disable=$(uci -q get ipv6.bakconfig.fw_disable)

		json_init
		json_add_int enabled "$1"
		json_add_string type "static"
		json_add_string wan_ipaddr "$wan_ipaddr"
		json_add_string wan_gateway "$wan_gateway"
		json_add_string lan_prefix "$lan_prefix"
		json_add_int lan_prefix_len "$lan_prefix_len"
		if [ "$peerdns" = "0" ]; then
			json_add_int dns_enabled "1"
			json_add_string dns1 "$dns1"
			json_add_string dns2 "$dns2"
		else
			json_add_int dns_enabled "0"
			json_add_string dns1 ""
			json_add_string dns2 ""
		fi

		if [ "$fw_disable" = "1" ]; then
			json_add_int fw_enable "0"
		else
			json_add_int fw_enable "1"
		fi

		json_close_object

		ubus call jdcapi.static web_set_ipv6_static "$(json_dump)"
	else
		logger -s "jd_ap_mode.sh: ipv6 conf error!"
	fi
}

function ipv6_ap_to_router() {
	[ -e /usr/sbin/ipv6_passthrough.sh ] && /usr/sbin/ipv6_passthrough.sh clear_config

	local ipv6_enabled=$(uci -q get ipv6.bakconfig.enabled)
	local ipv6_mode=$(uci -q get ipv6.bakconfig.mode)

	if [ "$ipv6_enabled" = "1" ]; then
		ipv6_ap_to_router_proc 1
	else
		if [ "$ipv6_mode" != "" -a "$ipv6_mode" != "off" ]; then
			ipv6_ap_to_router_proc 0
		else
			fw_disable=$(uci -q get ipv6.bakconfig.fw_disable)

			json_init
			json_add_int enabled "0"
			json_add_string type "relay"

			json_add_int dns_enabled "0"
			json_add_string dns1 ""
			json_add_string dns2 ""

			if [ "$fw_disable" = "1" ]; then
				json_add_int fw_enable "0"
			else
				json_add_int fw_enable "1"
			fi

			json_close_object

			ubus call jdcapi.static web_set_ipv6_relay "$(json_dump)"
			
			uci set ipv6.config.mode='off'
		fi
	fi
	
	uci del ipv6.bakconfig
	uci commit ipv6
}
