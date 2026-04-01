#!/bin/sh

. /lib/functions.sh

calculate_weekdays() {
	local value=$1
	local day=0
	local weekdays=""

	while [ $day -lt 7 ];
		do
		let "value=value >> 1"

		if [ "$(($value & 1))" = "1" ];then
			if [ "$weekdays" = "" ];then
				weekdays="$day"
			else
				weekdays="$weekdays $day"
			fi
		fi

		let day++
	done

	echo $weekdays
}

timed_blacklist_config_del() {
	local id="$1"

	[ `echo $id |grep cfg |wc -l` -eq 1 ] && {
		uci -q del jd_product.$id
	}
}

uci_save_day_timelist() {
	#echo $@
	local section=$1
	local day=$2
	local value1=$3
	local value2=$4
	local val=""
	local flag=0

	if [ "$value1" != "" -a "$value2" = "" ]; then
		val="${value1}"
		flag=1
	elif [ "$value1" != "" -a "$value2" != "" ]; then
		val="${value1} ${value2}"
		flag=2
	else
		return
	fi

	case $day in
	"0")
		uci set jd_product.$section.day0="${val}"
		uci set jd_product.$section.day0enable="1"
	;;
	"1")
		uci set jd_product.$section.day1="${val}"
		uci set jd_product.$section.day1enable="1"
	;;
	"2")
		uci set jd_product.$section.day2="${val}"
		uci set jd_product.$section.day2enable="1"
	;;
	"3")
		uci set jd_product.$section.day3="${val}"
		uci set jd_product.$section.day3enable="1"
	;;
	"4")
		uci set jd_product.$section.day4="${val}"
		uci set jd_product.$section.day4enable="1"
	;;
	"5")
		uci set jd_product.$section.day5="${val}"
		uci set jd_product.$section.day5enable="1"
	;;
	"6")
		uci set jd_product.$section.day6="${val}"
		uci set jd_product.$section.day6enable="1"
	;;
	"7")
		uci set jd_product.$section.day="${val}"
		if [ $flag = 1 ]; then
			uci set jd_product.$section.dayenable="1"
		elif [ $flag = 2 ]; then
			uci set jd_product.$section.dayenable="1 1"
		fi
	;;
	esac
}

timed_blacklist_config_add() {
	local id="$1"

	[ `echo $id |grep cfg |wc -l` -lt 1 ] && {
		return
	}

	local mac=$(uci -q get jd_product_old.$id.mac)
	local section=$(echo $mac|tr 'a-z' 'A-Z'|tr -d ':')

	local timeswitch=$(uci -q get jd_product_old.$id.timeswitch)

	if [ "$timeswitch" = "1" ]; then
		#add
		uci set jd_product.$section=blacklist

		uci set jd_product.$section.name=$(uci -q get jd_product_old.$id.name)
		uci set jd_product.$section.mac=$(uci -q get jd_product_old.$id.mac)
		uci set jd_product.$section.enable=1
		uci set jd_product.$section.mode=1

		if [ "$timeswitch" = "1" ]; then
			local starttime=$(uci -q get jd_product_old.$id.starttime)
			local endtime=$(uci -q get jd_product_old.$id.endtime)

			[ "$starttime" = "" -o "$endtime" = "" ] && return
			
			local start=`echo $starttime| tr -d ":"`
			local stop=`echo $endtime | tr -d ":"`

			local repeat=$(uci -q get jd_product_old.$id.repeat)
			case "$repeat" in
				"0")
					logger -t "blacklist" "Executed once and not processed!"
					uci set jd_product.$section.enable=1
					uci set jd_product.$section.mode=1
				;;
				"1")
					uci set jd_product.$section.enable=1
					uci set jd_product.$section.mode=1
					if [ $start -le $stop ]; then
						uci_save_day_timelist $section "7" $starttime-$endtime
					else
						uci_save_day_timelist $section "7" 00:00-$endtime $starttime-23:59
					fi
				;;
				"2")
					uci set jd_product.$section.enable=1
					uci set jd_product.$section.mode=2
					if [ $start -le $stop ]; then
						local days="1 2 3 4 5"
						for day in $days
						do
							uci_save_day_timelist $section $day $starttime-$endtime
						done
					else
						local days="1 2 3 4 5"
						for day in $days
						do	
							uci_save_day_timelist $section $day 00:00-$endtime $starttime-23:59
						done
					fi
				;;
				"3")
					local customize=$(uci -q get jd_product_old.$id.customize)
					[ -n "$customize" ] && {
						uci set jd_product.$section.enable=1
						uci set jd_product.$section.mode=2
						if [ $start -le $stop ]; then
							local days="$(calculate_weekdays $customize)"
							for day in $days
							do
								local day=`expr \( $day \+ 1 \) \% 7`
								uci_save_day_timelist $section $day $starttime-$endtime
							done
						else
							local days="$(calculate_weekdays $customize)"
							for day in $days
							do
								local day=`expr \( $day \+ 1 \) \% 7`
								uci_save_day_timelist $section $day 00:00-$endtime $starttime-23:59
							done
						fi
					}
				;;
			esac
		fi
	else
		#add
		uci set jd_product.$section=blacklist

		uci set jd_product.$section.name=$(uci -q get jd_product_old.$id.name)
		uci set jd_product.$section.mac=$(uci -q get jd_product_old.$id.mac)
		uci set jd_product.$section.enable=1
		uci set jd_product.$section.mode=3
	fi
}

timed_whitelist_config_add() {
	local id="$1"

	[ `echo $id |grep cfg |wc -l` -lt 1 ] && {
		return
	}

	local mac=$(uci -q get jd_product_old.$id.mac)
	local section=$(echo $mac|tr 'a-z' 'A-Z'|tr -d ':')

	#add
	uci set jd_product.W_$section=whitelist

	uci set jd_product.W_$section.name=$(uci -q get jd_product_old.$id.name)
	uci set jd_product.W_$section.mac=$(uci -q get jd_product_old.$id.mac)
	uci set jd_product.W_$section.enable=1
	uci set jd_product.W_$section.mode=1
}

if [ "$(uci -q get jd_product.accesscontrol.converted)" != "2" ]; then
	cp /etc/config/jd_product /etc/config/jd_product_old

	config_load jd_product
	config_foreach timed_blacklist_config_del blacklist

	config_load jd_product
	config_foreach timed_blacklist_config_del whiltelist

	config_load jd_product_old
	config_foreach timed_blacklist_config_add blacklist

	config_load jd_product_old
	config_foreach timed_whitelist_config_add whitelist

	uci set jd_product.accesscontrol.converted='2'
	uci commit jd_product

	rm /etc/config/jd_product_old -rf

	/usr/sbin/timed_blacklist_generate.sh &
fi
