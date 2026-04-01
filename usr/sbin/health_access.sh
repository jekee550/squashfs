#!/bin/sh

. /lib/functions.sh

handle_mac_config() {
	local id="$1"
	local gamble=0
	local porn=0
	local adult_product=0

	local learn_mode=$(uci -q get role_stainfo.$id.learn_mode)
	local temp_allow=$(uci -q get role_stainfo.$id.temp_allow)
	if [ "1" = "$learn_mode" ]; then
		gamble=1
		porn=1
		adult_product=1
	elif [ "1" == "$temp_allow" ]; then
		gamble=0
		porn=0
		adult_product=0
	else
		if [ "1" = "$2" ]; then
			gamble=1
		else
			gamble=0
		fi

		if [ "1" = "$3" ]; then
			porn=1
			adult_product=1
		else
			porn=0
			adult_product=0
		fi
	fi

	local macaddr=$(echo $id | sed -r 's/(..)/&:/g;s#:$##')

	if [ "$gamble" = "1" -o "$porn" = "1" -o "$adult_product" = "1" ]; then
		iptables -t nat -w -A heath_access_control -m mac --mac-source $macaddr -p udp -m udp --dport 53 -j REDIRECT --to-ports 53

		ip6tables -t nat -w -A heath_access_control -m mac --mac-source $macaddr -p udp -m udp --dport 53 -j REDIRECT --to-ports 53
	fi

	[ "$gamble" = "1" ] && {
		iptables -t nat -w -A heath_access_control -m mac --mac-source $macaddr -j internet_protect_one

		ip6tables -t nat -w -A heath_access_control -m mac --mac-source $macaddr -j internet_protect_one
	}

	[ "$porn" = "1" ] && {
		iptables -t nat -w -A heath_access_control -m mac --mac-source $macaddr -j internet_protect_two

		ip6tables -t nat -w -A heath_access_control -m mac --mac-source $macaddr -j internet_protect_two
	}

	[ "$adult_product" = "1" ] && {
		iptables -t nat -w -A heath_access_control -m mac --mac-source $macaddr -j internet_protect_three

		ip6tables -t nat -w -A heath_access_control -m mac --mac-source $macaddr -j internet_protect_three
	}
}

handle_rolegroup_config() {
        local id="$1"

	local gamble_enable=$(uci -q get role_group.$id.gamble_enable)
        local porn_enable=$(uci -q get role_group.$id.porn_enable)

	config_list_foreach $id mac handle_mac_config $gamble_enable $porn_enable
}

ap_mode=$(uci -q get system.@system[0].apmode_init)
re_mode=$(uci -q get system.@system[0].re_init)

if [ "$ap_mode" = "0" -a "$re_mode" = "0" ]; then
	logger -t "appfilter" "jdc harm rule add"
	/usr/sbin/jdc_harm_rule.sh addIpset
	/usr/sbin/jdc_harm_rule.sh delIptables
	/usr/sbin/jdc_harm_rule.sh addIptables

	config_load role_group
	config_foreach handle_rolegroup_config rolegroup
else
	logger -t "appfilter" "jdc harm rule del"
	/usr/sbin/jdc_harm_rule.sh delIptables
	/usr/sbin/jdc_harm_rule.sh delIpset
fi
