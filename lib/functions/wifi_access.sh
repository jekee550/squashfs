#!/bin/sh

wifi_switch_mode() {
	local mode=$1

	#1:whitelist 2:blacklist
	if [ "$mode" = "1" ]; then
		cfg80211tool ath0 maccmd 1
		cfg80211tool ath1 maccmd 1
		cfg80211tool ath2 maccmd 1 2>/dev/null
		cfg80211tool ath11 maccmd 1

		uci set wireless.ath0.macfilter='allow'
		uci set wireless.ath1.macfilter='allow'
		uci -q set wireless.ath2.macfilter='allow'
		uci set wireless.ath11.macfilter='allow'
		uci commit wireless
	else
		cfg80211tool ath0 maccmd 2
		cfg80211tool ath1 maccmd 2
		cfg80211tool ath2 maccmd 2 2>/dev/null
		cfg80211tool ath11 maccmd 2

	        uci set wireless.ath0.macfilter='deny'
        	uci set wireless.ath1.macfilter='deny'
		uci -q set wireless.ath2.macfilter='deny'
        	uci set wireless.ath11.macfilter='deny'
		uci commit wireless
	fi
}

wifi_clear_rule() {
	#清空列表
	uci -q del wireless.ath0.maclist
	uci -q del wireless.ath1.maclist
	uci -q del wireless.ath2.maclist
	uci -q del wireless.ath11.maclist

	uci commit wireless

	#清空
	cfg80211tool ath0 maccmd 3
	cfg80211tool ath1 maccmd 3
	cfg80211tool ath2 maccmd 3 2>/dev/null
	cfg80211tool ath11 maccmd 3

	#默认黑名单
	wifi_switch_mode 2
}

wifi_kick_user() {
	local macaddr=$1

	local ifaces="ath0 ath1 ath2"
	for iface in $ifaces
	do
		iwpriv $iface kickmac $macaddr 2>/dev/null
	done

	[ "0" == "$(uci -q get wireless.ath11.disabled)" ] && {
		iwpriv ath11 kickmac $macaddr
	}
}

wifi_del_maclist() {
	local macaddr=$1

	#hot del
	iwpriv ath0 delmac $macaddr
	iwpriv ath1 delmac $macaddr
	iwpriv ath2 delmac $macaddr 2>/dev/null

	[ "0" == "$(uci -q get wireless.ath11.disabled)" ] && {
		iwpriv ath11 delmac $macaddr
	}

	#conf del
	uci del_list wireless.ath0.maclist=$macaddr
	uci del_list wireless.ath1.maclist=$macaddr
	uci -q del_list wireless.ath2.maclist=$macaddr
	uci del_list wireless.ath11.maclist=$macaddr

	uci commit wireless
}

wifi_add_maclist() {
	local macaddr=$1

	#hot add
	iwpriv ath0 addmac $macaddr
	iwpriv ath1 addmac $macaddr
	iwpriv ath2 addmac $macaddr 2>/dev/null

	[ "0" == "$(uci -q get wireless.ath11.disabled)" ] && {
		iwpriv ath11 addmac $macaddr
	}

	#conf add
	uci add_list wireless.ath0.maclist=$macaddr
	uci add_list wireless.ath1.maclist=$macaddr
	uci -q add_list wireless.ath2.maclist=$macaddr
	uci add_list wireless.ath11.maclist=$macaddr

	uci commit wireless	
}

