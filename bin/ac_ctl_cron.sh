#!/bin/sh

. /lib/functions.sh
. /lib/functions/wifi_access.sh

UCI_COMMIT_FLAG=0

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

handle_blacklist() {
        local cfg="$1"

        local enable
        local mode
        local timeswitch

        config_get enable $cfg enable
        config_get mode $cfg mode

        if [ "$mode" != "3" -a "$mode" != "" ]; then
                return
        fi

        config_get timeswitch $cfg timeswitch
        if [ "$timeswitch" = "1" ];then
                local repeat
		local date_ymd
                local customize

		config_get repeat $cfg repeat
		config_get date_ymd $cfg date
		config_get customize $cfg customize

                local days
                if [ "$repeat" = "1" ];then
                        days="1,2,3,4,5,6,7"
                elif [ "$repeat" = "2" ];then
                        days="1,2,3,4,5"
                elif [ "$repeat" = "3" ];then
                        days=$(calculate_weekdays $customize)
                else
                        days=""
                fi

                local day=$(date +%w)
                if [ "$day" = "0" ];then
                        day="7"
                fi

                local mac
                local starttime
                local endtime

                config_get mac $cfg mac
                config_get starttime $cfg starttime
                config_get endtime $cfg endtime

                local start=`echo $starttime| tr -d ":"`
                local stop=`echo $endtime | tr -d ":"`
                if [ $start -le $stop ];then
                        local ret=`echo $days |grep $day`
                        if [ "$ret" != "" ]  || [ "$repeat" = "0" -a "$date_ymd" = "$(date '+%Y-%m-%d')" ];then
                                if [ "$(date '+%H:%M')" == "$starttime" ];then
                                        ebtables -t filter -D forwardcontrol -s $mac -j DROP
                                        ebtables -t filter -D inputcontrol -s $mac -j DROP

                                        ebtables -t filter -A forwardcontrol -s $mac -j DROP
                                        ebtables -t filter -A inputcontrol -s $mac -j DROP

                                        wifi_del_maclist $mac
                                        wifi_add_maclist $mac
                                        wifi_kick_user $mac
                                fi
                        else
                                ebtables -t filter -D forwardcontrol -s $mac -j DROP
                                ebtables -t filter -D inputcontrol -s $mac -j DROP

                                wifi_del_maclist $mac
                        fi

                        if [ "$(date '+%H:%M')" == "$endtime" ];then
                                ebtables -t filter -D forwardcontrol -s $mac -j DROP
                                ebtables -t filter -D inputcontrol -s $mac -j DROP

                                wifi_del_maclist $mac

				if [ "$repeat" = "0" -a "$date_ymd" = "$(date '+%Y-%m-%d')" ];then
					uci -q delete jd_product.$cfg

					local section=$(echo $mac|tr 'a-z' 'A-Z'|tr -d ':')
					uci -q set jd_stainfo.$section.net_enable='1'

					UCI_COMMIT_FLAG=1
				fi
                        fi
                else
                        local ret=`echo $days|grep $day`
                        if [ "$ret" != "" ] || [ "$repeat" = "0" -a "$date_ymd" = "$(date '+%Y-%m-%d')" ];then
                                if [ "$(date '+%H:%M')" == "$starttime" -o "$(date '+%H:%M')" == "00:00" ];then
                                        ebtables -t filter -D forwardcontrol -s $mac -j DROP
                                        ebtables -t filter -D inputcontrol -s $mac -j DROP

                                        ebtables -t filter -A forwardcontrol -s $mac -j DROP
                                        ebtables -t filter -A inputcontrol -s $mac -j DROP

                                        wifi_del_maclist $mac
                                        wifi_add_maclist $mac
                                        wifi_kick_user $mac
                                fi
                        else
                                ebtables -t filter -D forwardcontrol -s $mac -j DROP
                                ebtables -t filter -D inputcontrol -s $mac -j DROP

                                wifi_del_maclist $mac
                        fi

                        if [ "$(date '+%H:%M')" == "$endtime" -o "$(date '+%H:%M')" == "23:59" ];then
                                ebtables -t filter -D forwardcontrol -s $mac -j DROP
                                ebtables -t filter -D inputcontrol -s $mac -j DROP

                                wifi_del_maclist $mac

				if [ "$repeat" = "0" -a "$date_ymd" = "$(date '+%Y-%m-%d')" -a "$(date '+%H:%M')" = "23:59" ]; then
					uci -q delete jd_product.$cfg

					local section=$(echo $mac|tr 'a-z' 'A-Z'|tr -d ':')
					uci -q set jd_stainfo.$section.net_enable='1'

					UCI_COMMIT_FLAG=1
				fi
                        fi 
                fi
        fi
}

[ "$(uci -q get jd_product.accesscontrol.mode)" = "deny" -a $(uci show jd_product|grep -w blacklist |grep -w timeswitch=\'1\' | wc -l) -gt 0 ] && {
        config_load jd_product
        config_foreach handle_blacklist blacklist

	if [ $UCI_COMMIT_FLAG -eq 1 ]; then
		uci commit jd_stainfo
		uci commit jd_product
	fi
}

