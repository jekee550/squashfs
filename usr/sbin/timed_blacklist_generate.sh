#!/bin/sh

. /lib/functions.sh

timed_blacklist_config() {
	local id="$1"

	local enable=$(uci -q get jd_product.$id.enable)

	[ "$enable" != "1" ] && return

	local mode=$(uci -q get jd_product.$id.mode)

	[ "$mode" != "1" -a "$mode" != "2" ] && return

	#判断net_enable是否被修改过标志
	local is_prohibited=0

	local mac=$(uci -q get jd_product.$id.mac |tr 'a-z' 'A-Z')

	case "$mode" in
		"1")
		local day_time=$(uci -q get jd_product.$id.day)
		local day_enable=$(uci -q get jd_product.$id.dayenable)

		set -- $day_enable
		for time in ${day_time//' '/ } ; do
			if [ "$1" = "1" ]; then
				local timestart=`echo $time | awk -F '-' '{print $1}'`
				local timestop=`echo $time | awk -F '-' '{print $2}'`
				[ -n "$timestart" ] && [ -n "$timestop" ] && {
					local start_hour=`echo $timestart | awk -F ':' '{print $1}'`
					local start_min=`echo $timestart | awk -F ':' '{print $2}'`
					[ -n "$start_hour" ] && [ -n "$start_min" ] && {
						(crontab -l ; echo "$start_min $start_hour * * * /usr/sbin/timed_blacklist.sh add $mac") | crontab -
					}
				
					local stop_hour=`echo $timestop | awk -F ':' '{print $1}'`
					local stop_min=`echo $timestop | awk -F ':' '{print $2}'`
					[ -n "$stop_hour" ] && [ -n "$stop_min" ] && {
						(crontab -l ; echo "$stop_min $stop_hour * * * /usr/sbin/timed_blacklist.sh del $mac") | crontab -
					}

					local hour=`date +%H`
					local min=`date +%M`
					local current=`expr $hour \* 60 \+ $min`
					if [ $stop_hour -gt $start_hour ] || [ $stop_hour -eq $start_hour -a $stop_min -gt $start_min ]; then
						local start=`expr $start_hour \* 60 \+ $start_min`
						local stop=`expr $stop_hour \* 60 \+ $stop_min`
						if [ $current -ge $start -a $current -le $stop ]; then
							/usr/sbin/timed_blacklist.sh add $mac
							is_prohibited=1
						fi
					elif [ $stop_hour -lt $start_hour ] || [ $stop_hour -eq $start_hour -a $stop_min -lt $start_min ]; then
						local start=`expr $start_hour \* 60 \+ $start_min`
						local stop=`expr $stop_hour \* 60 \+ $stop_min`
						if [ $current -lt $stop -o $current -gt $start ]; then
							/usr/sbin/timed_blacklist.sh add $mac
							is_prohibited=1
						fi
					else
						logger -t timed_blasklist "wrong time: $start_hour:$start_min-$stop_hour:$stop_min !"
					fi
				}
			fi
			shift
		done
		;;

		"2")
		local days="0 1 2 3 4 5 6"
		for day in $days
		do
			local prefix="day"
			local suffix="enable"
			local day_enable=$(uci -q get jd_product.$id.$prefix$day$suffix)
			if [ "$day_enable" = "" -o "$day_enable" = "0" ]; then
				continue
			fi

			local day_time=$(uci -q get jd_product.$id.$prefix$day)

			for time in ${day_time//' '/ } ; do
				local timestart=`echo $time | awk -F '-' '{print $1}'`
				local timestop=`echo $time | awk -F '-' '{print $2}'`

				[ -n "$timestart" ] && [ -n "$timestop" ] && {
					local start_hour=`echo $timestart | awk -F ':' '{print $1}'`
					local start_min=`echo $timestart | awk -F ':' '{print $2}'`

					local stop_hour=`echo $timestop | awk -F ':' '{print $1}'`
					local stop_min=`echo $timestop | awk -F ':' '{print $2}'`

					local hour=`date +%H`
					local min=`date +%M`

					local current_weekday=`date +%w`
					local current=`expr $hour \* 60 \+ $min`

					if [ $stop_hour -gt $start_hour ] || [ $stop_hour -eq $start_hour -a $stop_min -gt $start_min ]; then
						[ $current_weekday -eq $day ] && {
							local start=`expr $start_hour \* 60 \+ $start_min`
							local stop=`expr $stop_hour \* 60 \+ $stop_min`
							if [ $current -ge $start -a $current -le $stop ]; then
								/usr/sbin/timed_blacklist.sh add $mac
								is_prohibited=1
							fi
						}
						[ -n "$start_hour" ] && [ -n "$start_min" ] && {
							local weekday=$day
							(crontab -l ; echo "$start_min $start_hour * * $weekday /usr/sbin/timed_blacklist.sh add $mac") | crontab -
						}

						[ -n "$stop_hour" ] && [ -n "$stop_min" ] && {
							local weekday=$day
							(crontab -l ; echo "$stop_min $stop_hour * * $weekday /usr/sbin/timed_blacklist.sh del $mac") | crontab -
						}
					elif [ $stop_hour -lt $start_hour ] || [ $stop_hour -eq $start_hour -a $stop_min -lt $start_min ]; then
						local start=`expr $start_hour \* 60 \+ $start_min`
						local stop=`expr $stop_hour \* 60 \+ $stop_min`
						local next_day=`expr \( $day \+ 1 \) \% 7`

						#echo "$current $stop $current_weekday $next_day $day $mac"
						
						if [ $current -lt $stop -a $current_weekday -eq $next_day ] || [ $current -gt $start -a $current_weekday -eq $day ]; then
							/usr/sbin/timed_blacklist.sh add $mac
							is_prohibited=1
						fi
						[ -n "$start_hour" ] && [ -n "$start_min" ] && {
							local weekday=$day
							(crontab -l ; echo "$start_min $start_hour * * $weekday /usr/sbin/timed_blacklist.sh add $mac") | crontab -
						}

						[ -n "$stop_hour" ] && [ -n "$stop_min" ] && {
							local weekday=`expr \( $day \+ 1 \) \% 7`
							(crontab -l ; echo "$stop_min $stop_hour * * $weekday /usr/sbin/timed_blacklist.sh del $mac") | crontab -
						}
					fi
				}
			done
		done
		;;
	esac

	#.......................................
	[ $is_prohibited -eq 0 -a "$(uci -q get jd_stainfo.$id)" = "station" ] && {
		uci -q set jd_stainfo.$id.net_enable='1'
		uci commit jd_stainfo.$id
	}
}

timed_blacklist_set() {
	config_load jd_product
	if [ "$1" = "allow" ]; then
		config_foreach timed_blacklist_config whitelist
	else
		config_foreach timed_blacklist_config blacklist
	fi
}

#clear all rules
clear_all_rules() {
	crontab -l |grep -v 'timed_blacklist' | crontab -

	wifi_clear_rule

	ebtables -t filter -F forwardcontrol 2>/dev/null
	ebtables -t filter -F inputcontrol 2>/dev/null

	iptables -t filter -F forwardcontrol 2>/dev/null
	iptables -t filter -F inputcontrol 2>/dev/null
	ip6tables -t filter -F forwardcontrol 2>/dev/null        
	ip6tables -t filter -F inputcontrol 2>/dev/null
}

#clear_all_rules

#黑名单和旧版定时黑名单设置
crontab -l |grep -v 'timed_blacklist' | crontab -
/bin/access_control.sh

#generate new rules
ap_mode=$(uci -q get system.@system[0].apmode_init)
re_mode=$(uci -q get system.@system[0].re_init)

#新版黑名单设置
[ "$ap_mode" = "0" -a "$re_mode" = "0" ] && {
	mode=$(uci -q get jd_product.accesscontrol.mode)

	if [ "$mode" = "allow" ]; then
		timed_blacklist_set allow
	else
		timed_blacklist_set deny
	fi
}

