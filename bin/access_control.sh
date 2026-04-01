#!/bin/sh

ENDTIME="23:59"
STARTTIME="00:00"

. /lib/functions.sh
. /lib/functions/wifi_access.sh

calculate_weekdays() {
	local value=$1
	local day=1
	local weekdays=""

	while [ $day -lt 8 ];
	do
		let "value=value >> 1"

		if [ "$(($value & 1))" == "1" ];then
			if [ "$weekdays" = "" ];then
				weekdays="$day"
			else
				weekdays="$weekdays,$day"
			fi
		fi

		let day++
	done

	echo $weekdays
}

ipt_whitelist_config() {
	local cfg="$1"
	local ipt="$2"

	local mac

	config_get mac $cfg mac

	$ipt -t filter -A forwardcontrol -m mac --mac-source $mac -j ACCEPT

	$ipt -t filter -A inputcontrol -m mac --mac-source $mac -j ACCEPT
}

ipt_blacklist_config() {
	local cfg="$1"
	local ipt="$2"

	local mode

	config_get mode $cfg mode

	if [ "$mode" != "3" -a "$mode" != "" ]; then
		return
	fi

	local mac
	local timeswitch

	config_get mac $cfg mac
	config_get timeswitch $cfg timeswitch

	if [ "$timeswitch" = "" -o "$timeswitch" = "0" ];then
		$ipt -t filter -A forwardcontrol -m mac --mac-source $mac -j DROP
		$ipt -t filter -A inputcontrol -m mac --mac-source $mac -j DROP
	else
		local repeat
		local customize
		local starttime
		local endtime
		local currentdate

		config_get repeat $cfg repeat
		config_get customize $cfg customize
		config_get starttime $cfg starttime
		config_get endtime $cfg endtime
		config_get currentdate $cfg date

		local start=`echo $starttime| tr -d ":"`
		local stop=`echo $endtime | tr -d ":"`

		case "$repeat" in
		"0")
			if [ $start -le $stop ];then
				local starttime="T$starttime"
				local endtime="T$endtime"

				$ipt -t filter -A forwardcontrol -m mac --mac-source $mac -m time --kerneltz --datestart $currentdate$starttime --datestop $currentdate$endtime -j DROP
				$ipt -t filter -A inputcontrol -m mac --mac-source $mac -m time --kerneltz --datestart $currentdate$starttime --datestop $currentdate$endtime -j DROP
			else
				local first_starttime="T$starttime"
				local first_endtime="T$ENDTIME"

				$ipt -t filter -A forwardcontrol -m mac --mac-source $mac -m time --kerneltz --datestart $currentdate$first_starttime --datestop $currentdate$first_endtime -j DROP
				$ipt -t filter -A inputcontrol -m mac --mac-source $mac -m time --kerneltz --datestart $currentdate$first_starttime --datestop $currentdate$first_endtime -j DROP

				local second_starttime="T$STARTTIME"
				local second_endtime="T$endtime"

				$ipt -t filter -A forwardcontrol -m mac --mac-source $mac -m time --kerneltz --datestart $currentdate$second_starttime --datestop $currentdate$second_endtime -j DROP
				$ipt -t filter -A inputcontrol -m mac --mac-source $mac -m time --kerneltz --datestart $currentdate$second_starttime --datestop $currentdate$second_endtime -j DROP
			fi
			;;
		"1")
			if [ $start -le $stop ];then
				$ipt -t filter -A forwardcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $starttime --timestop $endtime -j DROP
				$ipt -t filter -A inputcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $starttime --timestop $endtime -j DROP
			else
				local first_starttime=$starttime
				local first_endtime=$ENDTIME

				$ipt -t filter -A forwardcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $first_starttime --timestop $first_endtime -j DROP
				$ipt -t filter -A inputcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $first_starttime --timestop $first_endtime -j DROP

				local second_starttime=$STARTTIME
				local second_endtime=$endtime

				$ipt -t filter -A forwardcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $second_starttime --timestop $second_endtime -j DROP
				$ipt -t filter -A inputcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $second_starttime --timestop $second_endtime -j DROP
			fi
			;;
		"2")
			if [ $start -le $stop ];then
				$ipt -t filter -A forwardcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $starttime --timestop $endtime --weekdays 1,2,3,4,5 -j DROP
				$ipt -t filter -A inputcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $starttime --timestop $endtime --weekdays 1,2,3,4,5 -j DROP
			else
				local first_starttime=$starttime
				local first_endtime=$ENDTIME

				$ipt -t filter -A forwardcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $first_starttime --timestop $first_endtime --weekdays 1,2,3,4,5 -j DROP
				$ipt -t filter -A inputcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $first_starttime --timestop $first_endtime --weekdays 1,2,3,4,5 -j DROP

				local second_starttime=$STARTTIME
				local second_endtime=$endtime

				$ipt -t filter -A forwardcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $second_starttime --timestop $second_endtime --weekdays 1,2,3,4,5 -j DROP
				$ipt -t filter -A inputcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $second_starttime --timestop $second_endtime --weekdays 1,2,3,4,5 -j DROP
			fi
			;;
		"3")
			local days=$(calculate_weekdays $customize)
			if [ $start -le $stop ];then
				$ipt -t filter -A forwardcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $starttime --timestop $endtime --weekdays $days -j DROP
				$ipt -t filter -A inputcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $starttime --timestop $endtime --weekdays $days -j DROP
			else
				local first_starttime=$starttime
				local first_endtime=$ENDTIME

				$ipt -t filter -A forwardcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $first_starttime --timestop $first_endtime --weekdays $days -j DROP
				$ipt -t filter -A inputcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $first_starttime --timestop $first_endtime --weekdays $days -j DROP

				local second_starttime=$STARTTIME
				local second_endtime=$endtime

				$ipt -t filter -A forwardcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $second_starttime --timestop $second_endtime --weekdays $days -j DROP
				$ipt -t filter -A inputcontrol -m mac --mac-source $mac -m time --kerneltz --timestart $second_starttime --timestop $second_endtime --weekdays $days -j DROP
			fi
			;;
		esac
	fi

	local section=$(echo $mac|tr 'a-z' 'A-Z'|tr -d ':')
	local ip=$(uci -q get jd_stainfo.$section.ip)
	[ -n "$ip" ] && echo "$ip" > /proc/net/nf_conntrack
	[ -n "$ip" ] && ip neigh flush $ip
}

ipt_allow_rule() {
	local ipt="$1"

	$ipt -t filter -F forwardcontrol 2>/dev/null
	$ipt -t filter -D FORWARD -i br-lan -j forwardcontrol 2>/dev/null
	$ipt -t filter -X forwardcontrol 2>/dev/null

	$ipt -t filter -N forwardcontrol
	$ipt -t filter -I FORWARD -i br-lan -j forwardcontrol

	$ipt -t filter -F inputcontrol 2>/dev/null
	$ipt -t filter -D INPUT -i br-lan -j inputcontrol 2>/dev/null
	$ipt -t filter -X inputcontrol 2>/dev/null

	$ipt -t filter -N inputcontrol
	$ipt -t filter -I INPUT -i br-lan -j inputcontrol

	config_foreach ipt_whitelist_config whitelist $ipt

	$ipt -t filter -A forwardcontrol -j DROP
	$ipt -t filter -A inputcontrol -j DROP
}

ipt_deny_rule() {
	local ipt="$1"

	$ipt -t filter -F forwardcontrol 2>/dev/null
	$ipt -t filter -D FORWARD -i br-lan -j forwardcontrol 2>/dev/null
	$ipt -t filter -X forwardcontrol 2>/dev/null

	$ipt -t filter -N forwardcontrol
	$ipt -t filter -I FORWARD -i br-lan -j forwardcontrol

	$ipt -t filter -F inputcontrol 2>/dev/null
	$ipt -t filter -D INPUT -i br-lan -j inputcontrol 2>/dev/null
	$ipt -t filter -X inputcontrol 2>/dev/null

	$ipt -t filter -N inputcontrol
	$ipt -t filter -I INPUT -i br-lan -j inputcontrol

	config_foreach ipt_blacklist_config blacklist $ipt
}

ipt_clear_rule() {
	local ipt="$1"

	$ipt -t filter -F forwardcontrol 2>/dev/null
	$ipt -t filter -D FORWARD -i br-lan -j forwardcontrol 2>/dev/null
	$ipt -t filter -X forwardcontrol 2>/dev/null

	$ipt -t filter -F inputcontrol 2>/dev/null
	$ipt -t filter -D INPUT -i br-lan -j inputcontrol 2>/dev/null
	$ipt -t filter -X inputcontrol 2>/dev/null
}

ebt_whitelist_config() {
	local cfg="$1"

	local mac

	config_get mac $cfg mac

	ebtables -t filter -A forwardcontrol -s $mac -j ACCEPT

	ebtables -t filter -A inputcontrol -s $mac -j ACCEPT
}

ebt_blacklist_config() {
	local cfg="$1"

	local mode

	config_get mode $cfg mode

	if [ "$mode" != "3" -a "$mode" != "" ]; then
		return
	fi

	local mac
	local timeswitch

	config_get mac $cfg mac
	config_get timeswitch $cfg timeswitch

	if [ "$timeswitch" = "" -o "$timeswitch" = "0" ];then
		ebtables -t filter -A forwardcontrol -s $mac -j DROP
		ebtables -t filter -A inputcontrol -s $mac -j DROP
	else
		local repeat
		local customize
		local starttime
		local endtime
		local currentdate

		config_get repeat $cfg repeat
		config_get customize $cfg customize
		config_get starttime $cfg starttime
		config_get endtime $cfg endtime
		config_get currentdate $cfg date

		local start=`echo $starttime | tr -d ":"`
		local stop=`echo $endtime | tr -d ":"`
		local currenttime=$(date '+%H%M')

		local day=$(date +%w)
		if [ "$day" = "0" ];then
			day="7"
		fi

		case "$repeat" in
		"0")
			if [ $currentdate -eq $(date '+%Y-%m-%d') ]; then
				if [ $start -le $stop ];then
					if [ $currenttime -ge $start -a $currenttime -le $stop ];then
						ebtables -t filter -A forwardcontrol -s $mac -j DROP
						ebtables -t filter -A inputcontrol -s $mac -j DROP
					fi
				else
					if [ $currenttime -le $stop -a $currenttime -ge 0000 ] || [ $currenttime -ge $start -a $currenttime -le 2359 ];then
						ebtables -t filter -A forwardcontrol -s $mac -j DROP
						ebtables -t filter -A inputcontrol -s $mac -j DROP
					fi
				fi
			fi
			;;
		"1")
			local days="1,2,3,4,5,6,7"
			local ret=`echo $days |grep $day`
			if [ "$ret" != "" ];then
				if [ $start -le $stop ];then
					if [ $currenttime -ge $start -a $currenttime -le $stop ];then
						ebtables -t filter -A forwardcontrol -s $mac -j DROP
						ebtables -t filter -A inputcontrol -s $mac -j DROP
					fi
				else
					if [ $currenttime -le $stop -a $currenttime -ge 0000 ] || [ $currenttime -ge $start -a $currenttime -le 2359 ];then
						ebtables -t filter -A forwardcontrol -s $mac -j DROP
						ebtables -t filter -A inputcontrol -s $mac -j DROP
					fi
				fi
			fi
			;;
		"2")
			local days="1,2,3,4,5"
			local ret=`echo $days |grep $day`
			if [ "$ret" != "" ];then
				if [ $start -le $stop ];then
					if [ $currenttime -ge $start -a $currenttime -le $stop ];then
						ebtables -t filter -A forwardcontrol -s $mac -j DROP
						ebtables -t filter -A inputcontrol -s $mac -j DROP
					fi
				else
					if [ $currenttime -le $stop -a $currenttime -ge 0000 ] || [ $currenttime -ge $start -a $currenttime -le 2359 ];then
						ebtables -t filter -A forwardcontrol -s $mac -j DROP
						ebtables -t filter -A inputcontrol -s $mac -j DROP
					fi
				fi
			fi
			;;
		"3")
			local days=$(calculate_weekdays $customize)
			local ret=`echo $days |grep $day`
			if [ "$ret" != "" ];then
				if [ $start -le $stop ];then
					if [ $currenttime -ge $start -a $currenttime -le $stop ];then
						ebtables -t filter -A forwardcontrol -s $mac -j DROP
						ebtables -t filter -A inputcontrol -s $mac -j DROP
					fi
				else
					if [ $currenttime -le $stop -a $currenttime -ge 0000 ] || [ $currenttime -ge $start -a $currenttime -le 2359 ];then
						ebtables -t filter -A forwardcontrol -s $mac -j DROP
						ebtables -t filter -A inputcontrol -s $mac -j DROP
					fi
				fi
			fi
			;;
		esac
	fi
}

ebt_allow_rule() {
	if [ "$(uci -q get system.@system[0].cap_init)" = "1" ]; then
		ebtables -D INPUT -p 0x888e -j ACCEPT 2>/dev/null
		ebtables -A INPUT -p 0x888e -j ACCEPT
	else
		ebtables -D INPUT -p 0x888e -j ACCEPT 2>/dev/null
	fi

	ebtables -t filter -F forwardcontrol 2>/dev/null
	ebtables -t filter -D FORWARD --logical-in br-lan -j forwardcontrol 2>/dev/null
	ebtables -t filter -X forwardcontrol 2>/dev/null

	ebtables -t filter -N forwardcontrol
	ebtables -t filter -A FORWARD --logical-in br-lan -j forwardcontrol

	ebtables -t filter -F inputcontrol 2>/dev/null
	ebtables -t filter -D INPUT --logical-in br-lan -j inputcontrol 2>/dev/null
	ebtables -t filter -X inputcontrol 2>/dev/null

	ebtables -t filter -N inputcontrol
	ebtables -t filter -A INPUT --logical-in br-lan -j inputcontrol

	config_foreach ebt_whitelist_config whitelist

	ebtables -t filter -A forwardcontrol -j DROP
	ebtables -t filter -A inputcontrol -j DROP
}

ebt_deny_rule() {
	ebtables -D INPUT -p 0x888e -j ACCEPT 2>/dev/null

	ebtables -t filter -F forwardcontrol 2>/dev/null
	ebtables -t filter -D FORWARD --logical-in br-lan -j forwardcontrol 2>/dev/null
	ebtables -t filter -X forwardcontrol 2>/dev/null

	ebtables -t filter -N forwardcontrol -P RETURN
	ebtables -t filter -A FORWARD --logical-in br-lan -j forwardcontrol

	ebtables -t filter -F inputcontrol 2>/dev/null
	ebtables -t filter -D INPUT --logical-in br-lan -j inputcontrol 2>/dev/null
	ebtables -t filter -X inputcontrol 2>/dev/null

	ebtables -t filter -N inputcontrol -P RETURN
	ebtables -t filter -A INPUT --logical-in br-lan -j inputcontrol

	config_foreach ebt_blacklist_config blacklist
}

ebt_clear_rule() {
	ebtables -t filter -F forwardcontrol 2>/dev/null
	ebtables -t filter -D FORWARD --logical-in br-lan -j forwardcontrol 2>/dev/null
	ebtables -t filter -X forwardcontrol 2>/dev/null

	ebtables -t filter -F inputcontrol 2>/dev/null
	ebtables -t filter -D INPUT --logical-in br-lan -j inputcontrol 2>/dev/null
	ebtables -t filter -X inputcontrol 2>/dev/null
}

wifi_whitelist_config() {
	local cfg="$1"

	local mac

	config_get mac $cfg mac

	wifi_del_maclist $mac

	wifi_add_maclist $mac
}

wifi_blacklist_config() {
	local cfg="$1"

	local mode

	config_get mode $cfg mode

	if [ "$mode" != "3" -a "$mode" != "" ]; then
		return
	fi

	local mac
	local timeswitch

	config_get mac $cfg mac
	config_get timeswitch $cfg timeswitch

	local is_prohibited=0

	if [ "$timeswitch" = "" -o "$timeswitch" = "0" ];then
		wifi_del_maclist $mac
		wifi_add_maclist $mac
		wifi_kick_user $mac
	else
		local repeat
		local customize
		local starttime
		local endtime
		local currentdate

		config_get repeat $cfg repeat
		config_get customize $cfg customize
		config_get starttime $cfg starttime
		config_get endtime $cfg endtime
		config_get currentdate $cfg date

		local start=`echo $starttime | tr -d ":"`
		local stop=`echo $endtime | tr -d ":"`
		local currenttime=$(date '+%H%M')

		local day=$(date +%w)
		if [ "$day" = "0" ];then
			day="7"
		fi

		case "$repeat" in
		"0")
			if [ $currentdate -eq $(date '+%Y-%m-%d') ]; then
				if [ $start -le $stop ];then
					if [ $currenttime -ge $start -a $currenttime -le $stop ];then
						wifi_del_maclist $mac
						wifi_add_maclist $mac
						wifi_kick_user $mac

						is_prohibited=1
					fi
				else
					if [ $currenttime -le $stop -a $currenttime -ge 0000 ] || [ $currenttime -ge $start -a $currenttime -le 2359 ];then
						wifi_del_maclist $mac
						wifi_add_maclist $mac
						wifi_kick_user $mac

						is_prohibited=1
					fi
				fi
			fi
			;;
		"1")
			local days="1,2,3,4,5,6,7"
			local ret=`echo $days |grep $day`
			if [ "$ret" != "" ];then
				if [ $start -le $stop ];then
					if [ $currenttime -ge $start -a $currenttime -le $stop ];then
						wifi_del_maclist $mac
						wifi_add_maclist $mac
						wifi_kick_user $mac

						is_prohibited=1
					fi
				else
					if [ $currenttime -le $stop -a $currenttime -ge 0000 ] || [ $currenttime -ge $start -a $currenttime -le 2359 ];then
						wifi_del_maclist $mac
						wifi_add_maclist $mac
						wifi_kick_user $mac

						is_prohibited=1
					fi
				fi
			fi
			;;
		"2")
			local days="1,2,3,4,5"
			local ret=`echo $days |grep $day`
			if [ "$ret" != "" ];then
				if [ $start -le $stop ];then
					if [ $currenttime -ge $start -a $currenttime -le $stop ];then
						wifi_del_maclist $mac
						wifi_add_maclist $mac
						wifi_kick_user $mac

						is_prohibited=1
					fi
				else
					if [ $currenttime -le $stop -a $currenttime -ge 0000 ] || [ $currenttime -ge $start -a $currenttime -le 2359 ];then
						wifi_del_maclist $mac
						wifi_add_maclist $mac
						wifi_kick_user $mac

						is_prohibited=1
					fi
				fi
			fi
			;;
		"3")
			local days=$(calculate_weekdays $customize)
			local ret=`echo $days |grep $day`
			if [ "$ret" != "" ];then
				if [ $start -le $stop ];then
					if [ $currenttime -ge $start -a $currenttime -le $stop ];then
						wifi_del_maclist $mac
						wifi_add_maclist $mac
						wifi_kick_user $mac

						is_prohibited=1
					fi
				else
					if [ $currenttime -le $stop -a $currenttime -ge 0000 ] || [ $currenttime -ge $start -a $currenttime -le 2359 ];then
						wifi_del_maclist $mac
						wifi_add_maclist $mac
						wifi_kick_user $mac

						is_prohibited=1
					fi
				fi
			fi
			;;
		esac

		local section=$(echo $mac|tr 'a-z' 'A-Z'|tr -d ':')
		[ $is_prohibited -eq 1 -a "$(uci -q get jd_stainfo.$section)" = "station" ] && {
			uci -q set jd_stainfo.$section.net_enable='0'
			uci commit jd_stainfo.$section
		}
	fi
}

wifi_allow_rule() {
	wifi_clear_rule

	wifi_switch_mode 1

	config_foreach wifi_whitelist_config whitelist
}

wifi_deny_rule() {
	wifi_clear_rule

	wifi_switch_mode 2

	config_foreach wifi_blacklist_config blacklist
}

set_blacklist_device_flag() {
	local cfg="$1"
	local flag="$2"

	local mode

	config_get mode $cfg mode

	#新版定时黑名单
	[ $flag -eq 0 ] && {
		if [ "$mode" != "3" -a "$mode" != "" ]; then
			return
		fi
	}

	local mac
	local timeswitch

	config_get mac $cfg mac
	config_get timeswitch $cfg timeswitch

	#老版定时黑名单
	[ $flag -eq 0 ] && {
		if [ "$timeswitch" = "1" ]; then
			return
		fi
	}

	local section=$(echo $mac|tr 'a-z' 'A-Z'|tr -d ':')

	if [ "$(uci -q get jd_stainfo.$section)" = "station" ]; then
		if [ "$flag" = "1" ]; then
			uci -q set jd_stainfo.$section.net_enable='1'
		else
			uci -q set jd_stainfo.$section.net_enable='0'
		fi

		uci commit jd_stainfo.$section
	fi
}
set_whitelist_device_flag() {
	local cfg="$1"
	local flag="$2"

	local mode

	config_get mode $cfg mode

	#新版定时黑名单
	[ $flag -eq 0 ] && {
		if [ "$mode" != "3" -a "$mode" != "" ]; then
			return
		fi
	}

	local mac
	local timeswitch

	config_get mac $cfg mac
	config_get timeswitch $cfg timeswitch

	#老版定时黑名单
	[ $flag -eq 0 ] && {
		if [ "$timeswitch" = "1" ]; then
			return
		fi
	}

	local section=$(echo $mac|tr 'a-z' 'A-Z'|tr -d ':')

	if [ "$(uci -q get jd_stainfo.$section)" = "station" ]; then
		if [ "$flag" = "1" ]; then
			uci -q set jd_stainfo.$section.net_enable='1'
		else
			uci -q set jd_stainfo.$section.net_enable='0'
		fi

		uci commit jd_stainfo.$section
	fi
}
set_blacklist_device_net_enable() {
	local flag=$1

	if [ "$2" = "deny" ]; then
		config_foreach set_blacklist_device_flag blacklist $flag
	else
		config_foreach set_whitelist_device_flag whitelist $flag
	fi
}

ap_mode=$(uci -q get system.@system[0].apmode_init)
re_mode=$(uci -q get system.@system[0].re_init)

[ "$ap_mode" = "0" -a "$re_mode" = "0" ] && {
	config_load jd_product

	mode=$(uci -q get jd_product.accesscontrol.mode)

	case "$mode" in
		allow)
			#echo "allow"
			ipt_allow_rule iptables
			ipt_allow_rule ip6tables
			ebt_allow_rule
			wifi_allow_rule

			#清空黑名单标志
			set_blacklist_device_net_enable 1 allow

			/usr/sbin/devices_net_enable_update.sh whitelist
		;;
		deny)
			#echo "deny"
			ipt_deny_rule iptables
			ipt_deny_rule ip6tables
			ebt_deny_rule
			wifi_deny_rule

			#添加黑名单标志
			set_blacklist_device_net_enable 0 deny

			/usr/sbin/devices_net_enable_update.sh blacklist
		;;
		*)
			#echo "clear"
			ipt_clear_rule iptables
			ipt_clear_rule ip6tables
			ebt_clear_rule
			wifi_clear_rule
		;;
	esac

	if [ $(uci -q get jd_product.accesscontrol.mode) = "deny" -a $(uci show jd_product|grep -w blacklist |grep -w timeswitch=\'1\' | wc -l) -gt 0 ];then
		[ $(crontab -l | grep -w 'ac_ctl_cron.sh' | wc -l) -eq 0 ] && {
			(crontab -l ; echo '*/1 * * * * /bin/ac_ctl_cron.sh') | crontab -
		}
	else
		(crontab -l | grep -v 'ac_ctl_cron.sh') | crontab -
	fi
}

[ "$ap_mode" = "1" -o "$re_mode" = "1" ] && {
	ipt_clear_rule iptables
	ipt_clear_rule ip6tables
	ebt_clear_rule
	wifi_clear_rule

	(crontab -l | grep -v 'ac_ctl_cron.sh') | crontab -
}
