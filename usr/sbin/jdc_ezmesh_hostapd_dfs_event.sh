#!/bin/sh

#脚本调用关系
#hostapd_cli call me
# Parameter: ath16
# Parameter: CTRL-EVENT-CHANNEL-SWITCH
# Parameter: freq=5180
# Parameter: ht_enabled=1
# Parameter: ch_offset=1
# Parameter: ch_width=80
# Parameter: MHz
# Parameter: cf1=5210
# Parameter: cf2=0
# Parameter: dfs=0

IFNAME=$1
CMD=$2
#logger -t "jdc_ezmesh Get ${IFNAME} event" -p user.info "IFNAME=$IFNAME CMD=$CMD" 

case "$CMD" in
    CTRL-EVENT-CHANNEL-SWITCH)
	[ $(cat /tmp/sysinfo/product_name) = "RE-CS-06" ] && exit 0
		if echo "${IFNAME}" | grep -q "^ath[0-2]6$"; then
			freq=$3
			ht_enabled=$4
			ch_offset=$5
			ch_width=$6
			unit=$7
			cf1=$8
			cf2=$9
			dfs=$10
			# Check if each parameter contains an '=' sign and extract the value if present
			if echo "$freq" | grep -q "="; then
				freq="${freq#*=}"
			fi

			if echo "$ht_enabled" | grep -q "="; then
				ht_enabled="${ht_enabled#*=}"
			fi

			if echo "$ch_offset" | grep -q "="; then
				ch_offset="${ch_offset#*=}"
			fi

			if echo "$ch_width" | grep -q "="; then
				ch_width="${ch_width#*=}"
			fi

			if echo "$unit" | grep -q "="; then
				unit="${unit#*=}"
			fi

			if echo "$cf1" | grep -q "="; then
				cf1="${cf1#*=}"
			fi

			if echo "$cf2" | grep -q "="; then
				cf2="${cf2#*=}"
			fi

			if echo "$dfs" | grep -q "="; then
				dfs="${dfs#*=}"
			fi
			logger -t "jdc_ezmesh Get ${IFNAME} event" -p user.info \
			"IFNAME=$IFNAME CMD=$CMD freq=$freq ht_enabled=$ht_enabled ch_offset=$ch_offset ch_width=$ch_width unit=$unit cf1=$cf1 cf2=$cf2 dfs=$dfs"
			if [ "$freq" != "5180" -o "$ch_width" != "80" ];then
				cfg80211tool $IFNAME mode 11AHE80
				cfg80211tool $IFNAME channel 36
			fi
        fi
      ;;
	AP-STA-CONNECTED)
	    	if echo "${IFNAME}" | grep -q "^ath[0-2]6$"; then
			/usr/sbin/jdc_ezmesh_hyfi_bridge_check.sh &
		fi
	    ;;
    *)
        if echo "${IFNAME}" | grep -q "^ath[0-2]6$"; then
            echo "$@" > /dev/console
            logger -t "${IFNAME} event" -p user.info "jdc_ezmesh :$@" 
        fi
      ;;
esac
