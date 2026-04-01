#!/bin/sh

. /usr/share/libubox/jshn.sh
. /lib/functions.sh

if [ -e /lib/ipq806x.sh ];then
	dev_type=$(. /lib/ipq806x.sh && echo $(ipq806x_product_name))
elif [ -e /lib/ramips.sh ];then
	dev_type=$(. /lib/ramips.sh && echo $(ramips_product_name))
else
	dev_type=$(. /lib/functions.sh && echo $(product_name))
fi

version=0003

#/* 支持的产品信号 */
ATH_AX1800_PRO_MODEL="jdc-ss01"      #/* 亚瑟 */
ATH_AX6600_MODEL="RE-SS-02"          #/* 雅典娜 */
MTK_AX1800_ONLINE_MODEL="RE-CP-02"   #/* 鲁班 线上版 */
MTK_AX1800_CHANNEL_MODEL="RE-BP-02"  #/* 鲁班 渠道版 */
MTK_AX1800_ISP_MODEL="RE-OP-02"      #/* 鲁班 运营商版 */
MTK_AX1800_OLD_MODEL="jdc-cp02"      #/* 鲁班 老版本 */
ATH_NEZHA_MODEL360="RE-CS-04"        #/* 哪吒 360 */
ATH_HOUYI_MODEL="RE-CS-03"           #/* 后羿 */
MTK_BAILI_MODEL="RE-CP-03"           #/* 百里 */
ATH_NEZHA_MODEL="RE-OS-03U"          #/* 哪吒 */

[ "$dev_type" = "jdc-ss01" -o "$dev_type" = "RE-SS-02" -o $dev_type = $ATH_NEZHA_MODEL -o $dev_type = $ATH_HOUYI_MODEL -o $dev_type = $MTK_AX1800_ONLINE_MODEL -o $dev_type = $MTK_AX1800_OLD_MODEL -o $dev_type = $MTK_AX1800_ISP_MODEL -o $dev_type = $MTK_AX1800_CHANNEL_MODEL ] || return

CPU_IDLE_RHRESHOLD=0
CPU_USR_RHRESHOLD=0
CPU_SYS_RHRESHOLD=0
CPU_IO_RHRESHOLD=0
CPU_SIRQ_RHRESHOLD=0
if [ $dev_type = $ATH_NEZHA_MODEL -o $dev_type = $ATH_HOUYI_MODEL ];then
	PROCESS_CPU_RHRESHOLD=40             #/*单进程的CPU使用率*/
else
	PROCESS_CPU_RHRESHOLD=10
fi
LOAD_AVERAGE_RHRESHOLD=0
SOFTIRQ_SESSION_FRQ=50
MEMORY_MemAvailable_RHRESHOLD=40000
COUNTER_FILE="/tmp/guard/guard_script_counter"

EVENT_CPU_CODE="100031"
EVENT_MEM_CODE="130001"



TMP_CPU_FILE="/tmp/.cputop6.log"
CPUHIGN_COUNTER=0
CPUHIGN_USR_COUNTER=0
CPUHIGN_SYS_COUNTER=0
CPUHIGN_IO_COUNTER=0
CPUHIGN_SIRQ_COUNTER=0
CPUHIGN_LOAD_COUNTER=0
NET_CONNECT_COUNTER=0
#
# 判断$1是否包含于$2
#
#举例 if __jdc_stringContain 'aa' 'iiiaa'; then echo yes; else echo no; fi 输出yes
__jdc_stringContain() { [ -z "${2##*$1*}" ] && { [ -z "$1" ] || [ -n "$2" ] ;} ; }


__jdc_pause_aiec_process(){
	max_value=`awk 'BEGIN{max=0}{if ($2+0 > max+0) max=$2} END{print max}' /tmp/jdc_tmpflow.txt`
	[ -z "$max_value" ] && max_value=0
	[ "$(uci -q get smartqos.qos.mode)" = "2" ] && max_upload="$(uci -q get smartqos.qos.modeweb_maxupload)"

	#plugin跑量大于50M时
	if [ $max_value -gt $((50*1024*1024*300/8)) ];then
		#按60%限速
		limit_value=$((max_value/300/1024*6/10))
		#和上网优先模式配置值比较大小
		[ -n "$max_upload" -a $max_upload -lt $limit_value ] && limit_value="$max_upload"
		cus_maxupload="$(uci -q get smartqos.qos.cus_maxupload)"
		#未设置过cus_maxupload或与要限速值大小不一致
		[ -z "$cus_maxupload" ] || [ -n "$cus_maxupload" -a $cus_maxupload -ne $limit_value ] && {
			uci set smartqos.qos.cus_maxupload=$limit_value
			uci commit smartqos
			/etc/init.d/smart_qos restart
			return
		}
	fi

	if [ -n "$1" ];then
		if [ "$1" = "all" ];then
			kill -stop $(pgrep happ:vod) 2>/dev/null
			kill -stop $(pgrep btvdp*) 2>/dev/null
			kill -stop $(pgrep insta_agent) 2>/dev/null
			kill -stop $(pgrep centaurs) 2>/dev/null
			#kill -stop $(pgrep ks-agent) 2>/dev/null
			kill -stop $(pgrep nexusplugin::worker) 2>/dev/null
			kill -stop $(pgrep yfnode) 2>/dev/null
			kill -stop $(pgrep edge_client_arm32_small) 2>/dev/null
			kill -stop $(pgrep lego_server) 2>/dev/null
		fi
		return
	fi

	if [ -n "$(cat $TMP_CPU_FILE | awk 'NR==3{print}' | grep -E "btvdp|insta_agent|centaurs|happ:vod|edge_client_arm32_small|lego_server")" ];then
		if [ -n "$(cat $TMP_CPU_FILE | awk 'NR==3{print}' | grep happ:vod)" ];then
			kill -stop $(pgrep happ:vod)
		elif [ -n "$(cat $TMP_CPU_FILE | awk 'NR==3{print}' | grep btvdp)" ];then
			kill -stop $(pgrep btvdp*)
		elif [ -n "$(cat $TMP_CPU_FILE | awk 'NR==3{print}' | grep insta_agent)" ];then
			kill -stop $(pgrep insta_agent)
		elif [ -n "$(cat $TMP_CPU_FILE | awk 'NR==3{print}' | grep centaurs)" ];then
			kill -stop $(pgrep centaurs)
		elif [ -n "$(cat $TMP_CPU_FILE | awk 'NR==3{print}' | grep edge_client_arm32_small)" ];then
			kill -stop $(pgrep edge_client_arm32_small)
		elif [ -n "$(cat $TMP_CPU_FILE | awk 'NR==3{print}' | grep lego_server)" ];then
			kill -stop $(pgrep lego_server)
		fi
	elif [ -n "$(cat $TMP_CPU_FILE | awk 'NR==4{print}' | grep -E "btvdp|insta_agent|centaurs|happ:vod|edge_client_arm32_small|lego_server")" ];then
		if [ -n "$(cat $TMP_CPU_FILE | awk 'NR==4{print}' | grep happ:vod)" ];then
			kill -stop $(pgrep happ:vod)
		elif [ -n "$(cat $TMP_CPU_FILE | awk 'NR==4{print}' | grep btvdp)" ];then
			kill -stop $(pgrep btvdp*)
		elif [ -n "$(cat $TMP_CPU_FILE | awk 'NR==4{print}' | grep insta_agent)" ];then
			kill -stop $(pgrep insta_agent)
		elif [ -n "$(cat $TMP_CPU_FILE | awk 'NR==4{print}' | grep centaurs)" ];then
			kill -stop $(pgrep centaurs)
		elif [ -n "$(cat $TMP_CPU_FILE | awk 'NR==4{print}' | grep edge_client_arm32_small)" ];then
			kill -stop $(pgrep edge_client_arm32_small)
		elif [ -n "$(cat $TMP_CPU_FILE | awk 'NR==4{print}' | grep lego_server)" ];then
			kill -stop $(pgrep lego_server)
		fi
	else
		if [ ! -e /opt/etc/init.d/aiecplugin*A -a ! -e /opt/etc/init.d/aiecplugin*N ] || [ -n "$(ps | grep -E " T " | grep -v grep | grep happ:vod)" ];then
			[ $(uci -q get smartqos.qos.mode) -ne 0 -a $(uci -q get smartqos.qos.mode) -ne 3 ] && {
				kill -stop $(pgrep btvdp*) 2>/dev/null
				kill -stop $(pgrep centaurs) 2>/dev/null
			}
		else
			kill -stop $(pgrep happ:vod) 2>/dev/null
		fi
	fi
}

__jdc_restart_pluginall(){
	date_H=`date +%H`
	#避开午晚高峰
	[ $date_H -gt 11 -a $date_H -lt 14 ] || [ $date_H -gt 19 -a $date_H -lt 22 ] && return 0
	date_d=`date +%d`
	if [ -e /tmp/.jdc_aiec_restart_record ];then
		date_record_d=$(cat /tmp/.jdc_aiec_restart_record | awk '{print $1}')
		num_record=$(cat /tmp/.jdc_aiec_restart_record | awk '{print $2}')
		if [ "$date_d" != "$date_record_d" ];then
			echo $date_d 1 > /tmp/.jdc_aiec_restart_record
		else
			[ $num_record -gt 3 ] && return 1
			echo $date_d $((num_record+1)) > /tmp/.jdc_aiec_restart_record
		fi
	else
		echo $date_d 1 > /tmp/.jdc_aiec_restart_record
	fi

	for plugin in `ls /opt/etc/init.d/`
	do
		[ "$(uci get jd_plugin.$plugin.plugin_type)" = "aiec" ] && {
			/opt/etc/init.d/$plugin restart &
			sleep 1
		}
	done

	return 0
}

__network_connect_check(){
	if [ ! -f $COUNTER_FILE.connect ]; then
		echo 0 > $COUNTER_FILE.connect
	fi

	#无终端连接及极限模式,无需处理插件
	if [ -z "$(cat /proc/net/arp | grep br-lan)" -o $(uci -q get smartqos.qos.mode) -eq 3 -o $(uci -q get smartqos.qos.mode) -eq 0 ];then
		if [ -n "$(uci -q get jd_product.product.plugin_pause)" ];then
			uci set jd_product.product.plugin_pause=''
			uci commit jd_product
			echo 0 > "$COUNTER_FILE.connect"
		fi
		return
	fi

	syslogfile_name="$(ls /log/syslog.* | awk 'END{print}')"
	[ -z "$syslogfile_name" ] && syslogfile_name="$(ls /opt/log/syslog.* | awk 'END{print}')"

	#if [ $(cat /tmp/log/syslog* | grep new_state | wc -l) -gt 10 ] || [ -n "$syslogfile_name" -a $(zcat $syslogfile_name | grep new_state | wc -l) -gt 50 ];then
	if [ -z "$(uci -q get jd_product.product.plugin_pause)" -a "$1" = "pause" ];then
		uci set jd_product.product.plugin_pause='1'
		uci commit jd_product
		__jdc_report_event "$EVENT_CPU_CODE" "server plugin pause" "server plugin pause"
		echo 0 > "$COUNTER_FILE.connect"
		return
	fi

	if [ -n "$(uci -q get jd_product.product.plugin_pause)" ];then
		NET_CONNECT_COUNTER=$(cat "$COUNTER_FILE.connect")
		if [ $NET_CONNECT_COUNTER -gt 6 ];then
			uci set jd_product.product.plugin_pause=''
			uci commit jd_product
			echo 0 > "$COUNTER_FILE.connect"
			__jdc_report_event "$EVENT_CPU_CODE" "server plugin unpause" "server plugin unpause"
		else
			let NET_CONNECT_COUNTER++
			echo $NET_CONNECT_COUNTER > "$COUNTER_FILE.connect"
		fi
	fi
}

__jdc_para_init(){

    #cpu 阈值初始化
	if [ $dev_type = $ATH_NEZHA_MODEL -o $dev_type = $ATH_HOUYI_MODEL ];then
		CPU_IDLE_RHRESHOLD=10
		CPU_USR_RHRESHOLD=50
		CPU_SYS_RHRESHOLD=60
		CPU_IO_RHRESHOLD=40
		CPU_SIRQ_RHRESHOLD=40
		LOAD_AVERAGE_RHRESHOLD=20
		MEMORY_MemAvailable_RHRESHOLD=25000
		ABNORMAL_PROCESS_RHRESHOLD=4
		VMSWAP_RHRESHOLD=$((350*1024))
	else
		if [ $1 -gt 20 ];then
			CPU_SYS_RHRESHOLD=30
			CPU_IO_RHRESHOLD=30
			CPU_USR_RHRESHOLD=30
			VMSWAP_RHRESHOLD=$((250*1024))
			ABNORMAL_PROCESS_RHRESHOLD=2
			CPU_SIRQ_RHRESHOLD=35
		elif [ $1 -gt 10 ];then
			CPU_SYS_RHRESHOLD=40
			CPU_IO_RHRESHOLD=40
			CPU_USR_RHRESHOLD=40
			VMSWAP_RHRESHOLD=$((300*1024))
			ABNORMAL_PROCESS_RHRESHOLD=3
			CPU_SIRQ_RHRESHOLD=40
		else
			CPU_SYS_RHRESHOLD=50
			CPU_IO_RHRESHOLD=50
			CPU_USR_RHRESHOLD=50
			VMSWAP_RHRESHOLD=$((350*1024))
			ABNORMAL_PROCESS_RHRESHOLD=4
			CPU_SIRQ_RHRESHOLD=45
		fi
		CPU_IDLE_RHRESHOLD=15
		LOAD_AVERAGE_RHRESHOLD=10
		MEMORY_MemAvailable_RHRESHOLD=25000
	fi
	if [ ! -d "/tmp/guard/" ]; then
		mkdir /tmp/guard/
	fi
}


#####
#{
#	"module": "system",
#	"level": "WARN",
#	"code": "100012",
#	"time": "2024-01-22T17:43:32Z",
#	"msg": "cpu usage:100",
#	"sub": {
#		"name": "abnormal",
#		"msg": "CPU:  20% usr  60% sys   0% nic   0% idle   0% io   4% irq  16% sirq"
#	}
#}
######
#input $1:EVENT_CPU_CODE
#input $2:msg
#input $3:sub msg
#
#
__jdc_report_event(){
	local msg
	local submsg
	local code
	code=$1
	msg=$2
	submsg=$3

	# initialize JSON output structure
	json_init

	# add a boolean field
	#json_add_boolean foo 0

	# add a string, take care of escaping
	json_add_string module "system"
	json_add_string level "WARN"
	json_add_string code "$code"
	json_add_string time "$(date  +"%Y-%m-%dT%H:%M:%SZ")"
	json_add_string msg "$msg"

	# add an object (dictionary)
	json_add_object sub
	json_add_string name "abnormal"
	json_add_string msg  "$submsg"
	json_close_object

	# build JSON object and print to stdout
	report_jstr=$(json_dump)
	ubus -t 5 call jdcapi_evt report "$report_jstr"
	return

}


######
#input $1:"usr" or "sys" or "io" or "sirq"
#
#
__jdc_cpuhigh_counnt(){

    para1="$1"

	if [ ! -f "$COUNTER_FILE.$para1" ]; then
		echo 0 > "$COUNTER_FILE.$para1"
	fi
	if [ "$para1" = "usr" ];then
		CPUHIGN_USR_COUNTER=$(cat "$COUNTER_FILE.$para1")
		let CPUHIGN_USR_COUNTER++
		echo $CPUHIGN_USR_COUNTER > "$COUNTER_FILE.$para1"
	elif [ "$para1" = "sys" ];then
		CPUHIGN_SYS_COUNTER=$(cat "$COUNTER_FILE.$para1")
		let CPUHIGN_SYS_COUNTER++
		echo $CPUHIGN_SYS_COUNTER > "$COUNTER_FILE.$para1"
	elif [ "$para1" = "io" ];then
		CPUHIGN_IO_COUNTER=$(cat "$COUNTER_FILE.$para1")
		let CPUHIGN_IO_COUNTER++
		echo $CPUHIGN_IO_COUNTER > "$COUNTER_FILE.$para1"
	elif [ "$para1" = "sirq" ];then
		CPUHIGN_SIRQ_COUNTER=$(cat "$COUNTER_FILE.$para1")
		let CPUHIGN_SIRQ_COUNTER++
		echo $CPUHIGN_SIRQ_COUNTER > "$COUNTER_FILE.$para1"
	elif [ "$para1" = "load_average" ];then
		CPUHIGN_LOAD_COUNTER=$(cat "$COUNTER_FILE.$para1")
		let CPUHIGN_LOAD_COUNTER++
		echo $CPUHIGN_LOAD_COUNTER > "$COUNTER_FILE.$para1"
	elif [ "$para1" = "" ];then
		CPUHIGN_COUNTER=$(cat "$COUNTER_FILE.$para1")
		let CPUHIGN_COUNTER++
		echo $CPUHIGN_COUNTER > "$COUNTER_FILE.$para1"
	fi
}



__jdc_get_mem_info() {
    local MemAvailable
	local Mem_cached
	MemAvailable=$(cat /proc/meminfo | grep MemAvailable | awk '{print $2}')
	Mem_cached=$(cat /proc/meminfo | grep -w Cached | awk '{print $2}')
	eval "$1=$MemAvailable"
	eval "$2=$Mem_cached"
}


__jdc_deal_swap_info() {
	[ $dev_type != $ATH_NEZHA_MODEL -a $dev_type != $ATH_HOUYI_MODEL ] || return
	#查找swap占用超过VMSWAP_RHRESHOLD的进程并kill
	for name in $(ls /proc/*/status)
	do
		Vminfo="$(cat $name | grep VmSwap:)"
		if [ -n "$Vminfo" ] && [ $(echo $Vminfo | awk '{print $2}') -gt $VMSWAP_RHRESHOLD ];then
			commm="$(cat /proc/$(cat $name | grep -w "Pid:" | awk '{print $2}')/comm)"
			logger "$0: $commm vmswap is high!!!!"
			__jdc_report_event "$EVENT_MEM_CODE" "vmswap" "$commm"
			kill -9 $(cat $name | grep -w "Pid:" | awk '{print $2}') 2>/dev/null
			return 0
		fi
	done
	#当Slab占用正常(小于200M)时，swap仍然占用高才考虑重启插件
	tmp_swapfree=$((512*1024-$VMSWAP_RHRESHOLD-100*1024))
	if [ $(cat /proc/meminfo | grep Slab: | awk '{print $2}') -lt $((200*1024)) ] && [ $(cat /proc/meminfo | grep SwapFree: | awk '{print $2}') -lt $tmp_swapfree ];then
		if ! __jdc_restart_pluginall;then
			__jdc_pause_aiec_process
		fi
	fi

	return 0
}

__jdc_deal_ipes_stopx() {
	[ $dev_type != $ATH_NEZHA_MODEL -a $dev_type != $ATH_HOUYI_MODEL ] || return
	#处理多个ipes stopx进程卡住的问题
	ipes_pids=$(ps | grep "ipes stopx" | grep -v grep | awk '{print $1}')
	ipes_pids_num=$(echo "$ipes_pids"| wc -l)
	[ $ipes_pids_num -gt 1 ] && echo "$ipes_pids" | xargs kill -9 > /dev/null 2>&1
}

__jdc_deal_docker_ps() {
	[ $dev_type != $ATH_NEZHA_MODEL -a $dev_type != $ATH_HOUYI_MODEL ] || return
	#处理多个docker ps进程卡住的问题
	docker_pids=$(ps | grep "docker ps" | grep -v grep | awk '{print $1}')
	docker_pids_num=$(echo "$docker_pids"| wc -l)
	[ $docker_pids_num -gt 2 ] && echo "$docker_pids" | xargs kill -9 > /dev/null 2>&1

	docker_pids=
	docker_pids=$(ps | grep "docker images" | grep -v grep | awk '{print $1}')
	docker_pids_num=$(echo "$docker_pids"| wc -l)
	[ $docker_pids_num -gt 2 ] && echo "$docker_pids" | xargs kill -9 > /dev/null 2>&1
}

__jdc_deal_process_DZ() {
	#D，Z状态进程数量超过3，进行上报
	[ $dev_type != $ATH_NEZHA_MODEL -a $dev_type != $ATH_HOUYI_MODEL ] || return
	ps | grep -E " D | Z " | grep -v grep > /tmp/.jdc_abn_process
	if [ $(cat /tmp/.jdc_abn_process | wc -l) -ge $ABNORMAL_PROCESS_RHRESHOLD ];then
		logger "$0: abnormal process: $(cat /tmp/.jdc_abn_process) !!!!"
		ubus -t 5 call jdcapi_evt report "{\"module\":\"system\",\"level\":\"WARN\",\"code\":\"130002\",\"time\":\"$(date +"%Y-%m-%dT%TZ")\",\"msg\":\"process abnormal\",\"sub\":\"$(cat /tmp/.jdc_abn_process)\"}"
		#查找sleep的父进程
		sleep_pid=
		sleep_ppid=
		sleep_pid=$(cat /tmp/.jdc_abn_process | grep sleep | awk 'NR==1{print $1}')
		[ -n "$sleep_pid" ] && sleep_ppid=$(cat /proc/$sleep_pid/status | grep PPid | awk '{print $2}')
		if [ -n "$(cat /tmp/.jdc_abn_process | grep -E "bt_procmgr|btvdp|bt_watchdog|bt_agent|by-agent|by-watcher")" ] || [ -n "$sleep_ppid" -a -n "$(cat /proc/$sleep_ppid/comm | grep -E "bt_procmgr|btvdp|bt_watchdog|bt_agent")" ];then
			if [ -e /tmp/.jdc_tmp_abnormal_D ];then
				/opt/etc/init.d/aiecplugin*D restart &
				rm /tmp/.jdc_tmp_abnormal_D
			else
				touch /tmp/.jdc_tmp_abnormal_D
			fi
		else
			rm -f /tmp/.jdc_tmp_abnormal_D
		fi

		if [ -n "$(cat /tmp/.jdc_abn_process | grep -E "/storage/centaurs|/storage/agent")" ];then
			if [ -e /tmp/.jdc_tmp_abnormal_E ];then
				/opt/etc/init.d/aiecplugin*E restart &
				rm /tmp/.jdc_tmp_abnormal_E
			else
				touch /tmp/.jdc_tmp_abnormal_E
			fi
		else
			rm -f /tmp/.jdc_tmp_abnormal_E
		fi

		if [ -n "$(cat /tmp/.jdc_abn_process | grep docker-runc)" ];then
			if [ -e /tmp/.jdc_tmp_abnormal_dockc ];then
				/opt/etc/init.d/jdc_docker restart &
				rm /tmp/.jdc_tmp_abnormal_dockc
			else
				touch /tmp/.jdc_tmp_abnormal_dockc
			fi
		else
			rm -f /tmp/.jdc_tmp_abnormal_dockc
		fi
	else
		rm -f /tmp/.jdc_tmp_abnormal_D
		rm -f /tmp/.jdc_tmp_abnormal_E
		rm -f /tmp/.jdc_tmp_abnormal_dockc
	fi
}

__jdc_deal_process_meminfo(){
#Slab占用超过200M，进行上报
	[ $(cat /proc/meminfo | grep Slab: | awk '{print $2}') -gt $((200*1024)) ] && {
		logger "$0: Slab is high!!!!"
		ubus -t 5 call jdcapi_evt report "{\"module\":\"system\",\"level\":\"WARN\",\"code\":\"130003\",\"time\":\"$(date +"%Y-%m-%dT%TZ")\",\"msg\":\"Slab is high\",\"sub\":\"Slab\"}"
	}

	__jdc_get_mem_info _Available_Mem _Cached_Mem

	if [ $_Available_Mem -lt $MEMORY_MemAvailable_RHRESHOLD -a $_Cached_Mem -lt $MEMORY_MemAvailable_RHRESHOLD ] ;then
		__jdc_report_event "$EVENT_MEM_CODE" "available mem" "$_Available_Mem $_Cached_Mem"
	fi

}

__jdc_deal_session_num(){
	iptables -w -t mangle "$1" PREROUTING -i br-lan -s 0.0.0.0/0 -p udp -m conntrack --ctstate NEW -j DROP 2>/dev/null
	iptables -w -t mangle "$1" PREROUTING -i br-lan -s 0.0.0.0/0 -p udp -m conntrack --ctstate NEW -m limit --limit $SOFTIRQ_SESSION_FRQ/s --limit-burst 100 -j ACCEPT 2>/dev/null
}

__jdc_clear_plugin_session(){
	classid_k_dec=1048580
	class_id=1048580
	if [ -f /opt/etc/firewall.$classid_k_dec ];then
		sh /opt/etc/firewall.$classid_k_dec del
		rm -f /opt/etc/firewall.$classid_k_dec
	fi

	if [ -n "$(iptables -nvL OUTPUT | grep conn | grep reject)" ];then
		for line in $(iptables -nvL OUTPUT --line-number 2>/dev/null | grep $class_id |awk '{print $1}' | sort -nr);do
			iptables -w -D OUTPUT $line
		done

		for line in $(iptables -nvL INPUT --line-number 2>/dev/null | grep $class_id |awk '{print $1}' | sort -nr);do
			iptables -w -D INPUT $line
		done

		for line in $(ip6tables -nvL OUTPUT --line-number 2>/dev/null | grep $class_id |awk '{print $1}' | sort -nr);do
			ip6tables -w -D OUTPUT $line
		done

		for line in $(ip6tables -nvL INPUT --line-number 2>/dev/null | grep $class_id |awk '{print $1}' | sort -nr);do
			ip6tables -w -D INPUT $line
		done
	fi
}

__jdc_deal_plugin_session(){
	nf_org_count=`cat /proc/sys/net/netfilter/nf_conntrack_count`

	for class_id in `cat /opt/etc/aiecplugin*K.sh | grep classid_dec= | awk -F "=" '{print $2}'`
	do
		aiec_file=/opt/etc/firewall.$class_id
		[ -f $aiec_file ] && nf_org_count=$(cat $aiec_file | grep nf_count | awk -F "=" '{print $2}')
		[ -z "$nf_org_count" ] && nf_org_count=`cat /proc/sys/net/netfilter/nf_conntrack_count`
	done

	if [ -z "$aiec_file" ];then
		if [ -z "$(lsmod | grep h323)" ];then
			logger "jdc-system-regular-check.sh: insmod h323"
			insmod nf_conntrack_h323;insmod nf_nat_h323
		fi
		__jdc_clear_plugin_session
		return
	fi

	if [ -n "$(lsmod | grep h323)" ];then
		logger "jdc-system-regular-check.sh: rmmod h323"
		rmmod nf_nat_h323;rmmod nf_conntrack_h323
	fi

	[ $# -eq 2 ] && logger "jdc-system-regular-check.sh: $@"

	max_value=`awk 'BEGIN{max=0}{if ($2+0 > max+0) max=$2} END{print max}' /tmp/jdc_tmpflow.txt`
	[ -z "$max_value" ] && max_value=0

	#跑量大于4Mbps
	if [ $max_value -gt $((4*1024*1024*300/8)) ];then
		__jdc_clear_plugin_session
		return
	fi

	[ $# -eq 2 ] || return

	if [ "$2" == "sub" ];then
		#[ $(cat /tmp/log/syslog | grep new_state | wc -l) -gt 5 ] || return
		[ $nf_org_count -gt 300 ] || return

		if [ $nf_org_count -gt 10000 ];then
			nf_count=$(($nf_org_count/2))
		else
			nf_count=$(($nf_org_count*2/3))
		fi
	elif [ "$2" == "inc" ];then
		[ -n "$(iptables -nvL OUTPUT | grep conn | grep reject)" ] || return
		nf_count=$(($nf_org_count*5/4))
	else
		return
	fi

	for class_id in `cat /opt/etc/aiecplugin*K.sh | grep classid_dec= | awk -F "=" '{print $2}'`
	do
		aiec_file=/opt/etc/firewall.$class_id

		echo "#!/bin/sh" > $aiec_file

		echo "nf_count=$nf_count" >> $aiec_file
		echo "for line in \$(iptables -nvL OUTPUT --line-number 2>/dev/null | grep $class_id |awk '{print \$1}' | sort -nr);do" >> $aiec_file
		echo "	iptables -w -D OUTPUT \$line" >> $aiec_file
		echo "done" >> $aiec_file
		echo "for line in \$(iptables -nvL INPUT --line-number 2>/dev/null | grep $class_id |awk '{print \$1}' | sort -nr);do" >> $aiec_file
		echo "	iptables -w -D INPUT \$line" >> $aiec_file
		echo "done" >> $aiec_file

		echo "for line in \$(ip6tables -nvL OUTPUT --line-number 2>/dev/null | grep $class_id |awk '{print \$1}' | sort -nr);do" >> $aiec_file
		echo "	ip6tables -w -D OUTPUT \$line" >> $aiec_file
		echo "done" >> $aiec_file
		echo "for line in \$(ip6tables -nvL INPUT --line-number 2>/dev/null | grep $class_id |awk '{print \$1}' | sort -nr);do" >> $aiec_file
		echo "	ip6tables -w -D INPUT \$line" >> $aiec_file
		echo "done" >> $aiec_file

		echo "[ \"\$1\" = \"del\" ] && return" >> $aiec_file
		echo "iptables -w -I OUTPUT -m cgroup --cgroup $class_id -m connlimit --connlimit-above $nf_count --connlimit-mask 0 -j REJECT" >> $aiec_file
		echo "iptables -w -I INPUT -m cgroup --cgroup $class_id -m connlimit --connlimit-above $nf_count --connlimit-mask 0 -j REJECT" >> $aiec_file

		echo "ip6tables -w -I OUTPUT -m cgroup --cgroup $class_id -m connlimit --connlimit-above $nf_count --connlimit-mask 0 -j REJECT" >> $aiec_file
		echo "ip6tables -w -I INPUT -m cgroup --cgroup $class_id -m connlimit --connlimit-above $nf_count --connlimit-mask 0 -j REJECT" >> $aiec_file
		__jdc_report_event "$EVENT_CPU_CODE" "plugin $class_id" "nf_conntrack_count $nf_count"
		echo "logger \"jdc-system-regular-check.sh: plugin $class_id, nf_conntrack_count $nf_count\"" >> $aiec_file
		chmod +x $aiec_file
		sh $aiec_file
	done
}

######
#input $1:"pause" "unpause"
#
__jdc_docker_pause(){
	_pause="$1"
	if [ $dev_type = $ATH_NEZHA_MODEL -o $dev_type = $ATH_HOUYI_MODEL ];then
		[ -n "$(pgrep dockerd)" ] || return
		[ ! -f /tmp/.jdguard_docker_status ] && echo "unpause" > /tmp/.jdguard_docker_status
		docker_status=$(cat /tmp/.jdguard_docker_status)

		for dir in $(find /sys/fs/cgroup/docker -mindepth 1 -maxdepth 1 -type d); do
			dir_name=$(basename "$dir")
			short_id=${dir_name:0:12}
			if [ "$docker_status" = "unpause" -a "$_pause" = "pause" ] || [ "$docker_status" = "pause" -a "$_pause" = "unpause" ]; then
				docker $_pause $short_id &
				echo "$_pause" > /tmp/.jdguard_docker_status
				logger "$0:__jdc_docker_pause $_pause !!!!"
			fi
		done
	fi
}


# output: $1 - usr_cpu
# output: $2 - sys_cpu
# output: $3 - idle_cpu
# output: $4 - io_cpu
# output: $5 - sirq_cpu
# output: $6 - process_command
# output: $7 - process_killed_pid
# output: $8 - load_average

__jdc_parse_cputop_info() {
	local line
	local used_mem
	local free_mem
	local shrd_mem
	local buff_mem
	local usr_cpu
	local sys_cpu
	local nic_cpu
	local idle_cpu
	local io_cpu
	local irq_cpu
	local sirq_cpu
	local process_pid
	local process_cpu
	local process_command
	local process_killed_pid
	local process_killed_command
	local Load_average

    # 检查文件是否存在
    if [ ! -f $TMP_CPU_FILE ]; then
        echo "文件不存在"
        return 1
    fi

    # 读取文件并提取内存信息
    while read -r line; do
        case "$line" in
            CPU:*)
                # 使用awk提取数字并通过管道传递给read命令
					usr=$(echo $line | awk '{print $2}')
					sys=$(echo $line | awk '{print $4}')
					nic=$(echo $line | awk '{print $6}')
					idle=$(echo $line | awk '{print $8}')
					io=$(echo $line | awk '{print $10}')
					irq=$(echo $line | awk '{print $12}')
					sirq=$(echo $line | awk '{print $14}')
					# 移除'%'并赋值给变量
					usr_cpu=${usr%\%}
					sys_cpu=${sys%\%}
					nic_cpu=${nic%\%}
					idle_cpu=${idle%\%}
					io_cpu=${io%\%}
					irq_cpu=${irq%\%}
					sirq_cpu=${sirq%\%}
					eval "$1='$usr_cpu'"
					eval "$2='$sys_cpu'"
					eval "$3='$idle_cpu'"
					eval "$4='$io_cpu'"
					eval "$5='$sirq_cpu'"
                ;;
            *average*)
					# 10min的负载
					Load_average=$(echo $line | awk '{print $4}')
                    Load_average=$(printf "%.0f" $Load_average)
					eval "$8='$Load_average'"
                ;;
             *)
                # 使用awk提取数字并通过管道传递给read命令
				process_pid=$(echo "$line" | tr -s ' ' |cut -d ' ' -f 1)
				#process_ppid=$(echo "$line" | cut -d ' ' -f 2)
				#process_user=$(echo "$line" | cut -d ' ' -f 3)
				#process_state=$(echo "$line" | cut -d ' ' -f 4)
				#process_vsz=$(echo "$line" | cut -d ' ' -f 5)
				#process_vsz_p=$(echo "$line" | cut -d ' ' -f 6)
				process_cpu=$(echo "$line" | tr -s ' ' |cut -d ' ' -f 7)
				process_cpu=${process_cpu%\%}
				process_command=$(echo "$line" | tr -s ' '|cut -d ' ' -f 8-)

				# 打印变量值，用于验证
				#echo "process_command: $process_command"
				#echo "process_pid: $process_pid"
				#echo "process_cpu: $process_cpu%"
				if [ $process_cpu -ge $PROCESS_CPU_RHRESHOLD ];then
				    process_killed_pid="$process_killed_pid $process_pid"
					process_killed_command="$process_killed_command $process_command"
				fi
                ;;
        esac
    done < $TMP_CPU_FILE
	eval "$6='$process_killed_command'"
	eval "$7='$process_killed_pid'"

	return 0
}
# 调用函数



__jdc_dealcpuinfo_Details()
{

	local _Available_Mem
	local _usr_cpu
	local _sys_cpu
	local _idle_cpu
	local _io_cpu
	local _sirq_cpu
	local _process_pid
	local _process_command
	local _process_need_killed
	local _sys_load_average
	local docker_pause_flag

	__jdc_deal_plugin_session "$@"
	[ "$1" = "plugin_session" ] && return

	top -n1 |  grep -v -E "top|grep|Mem|PPID|\[" |head -n 6 > $TMP_CPU_FILE
	__jdc_parse_cputop_info _usr_cpu _sys_cpu _idle_cpu _io_cpu _sirq_cpu _process_command _process_killed_pid _sys_load_average
	#echo "_usr_cpu $_usr_cpu _sys_cpu $_sys_cpu _idle_cpu $_idle_cpu _io_cpu $_io_cpu _sirq_cpu $_sirq_cpu _process_command $_process_command _process_killed_pid $_process_killed_pid _sys_load_average $_sys_load_average"
	#cpu

	__network_connect_check "$@"

	__jdc_para_init $_sys_load_average

	if [ $_idle_cpu -ge $CPU_IDLE_RHRESHOLD -a $_sys_load_average -lt $LOAD_AVERAGE_RHRESHOLD ];then
	    echo 0 > "$COUNTER_FILE."
		echo 0 > "$COUNTER_FILE.usr"
		echo 0 > "$COUNTER_FILE.sys"
		echo 0 > "$COUNTER_FILE.io"
		echo 0 > "$COUNTER_FILE.sirq"
		echo 0 > "$COUNTER_FILE.load_average"
		#kill -cont $(ps | grep -E " T " | grep -v grep | awk '{print $1}') 2>/dev/null
		if [ -e /tmp/.jdc_tmp_restore ];then
			T_pids=$(ps | grep -E " T " | grep -v grep | awk '{print $1}')
			for piddd in $T_pids
			do
				kill -cont $piddd
				break
			done
			[ -z "$T_pids" ] && {
				if [ -n "$(uci -q get smartqos.qos.cus_maxupload)" ];then
					uci set smartqos.qos.cus_maxupload=''
					uci commit smartqos
					/etc/init.d/smart_qos restart
				else
					__jdc_deal_session_num "-D"
				fi
			}
			__jdc_docker_pause "unpause"
			rm /tmp/.jdc_tmp_restore
		else
			touch /tmp/.jdc_tmp_restore
		fi
		[ -z "$(uci -q get jd_product.product.plugin_pause)" ] && return 0
	fi

	rm -f /tmp/.jdc_tmp_restore
	#CPU高计数统计
	[ $_idle_cpu -lt $CPU_IDLE_RHRESHOLD ] && __jdc_cpuhigh_counnt || echo 0 > "$COUNTER_FILE"
	if [ $CPUHIGN_COUNTER -eq 2 ];then	#CPU连续高的第二次

		[ $_usr_cpu -gt $CPU_USR_RHRESHOLD -o $_sys_cpu -gt $CPU_SYS_RHRESHOLD -o  $_io_cpu -gt $CPU_IO_RHRESHOLD -o $_sirq_cpu -gt $CPU_SIRQ_RHRESHOLD ] && {
			#只用于ax3000
			[ $(uci -q get smartqos.qos.mode) -ne 3 -a $(uci -q get smartqos.qos.mode) -ne 0 ] && __jdc_docker_pause "pause"
		}
	fi

	[ $(ps | grep "/usr/sbin/ezmesh" | grep -v grep | wc -l) -gt 1 ] && killall -9 ezmesh

	__jdc_deal_ipes_stopx

	__jdc_deal_docker_ps

	__jdc_deal_process_meminfo

	__jdc_deal_process_DZ

	[ $_usr_cpu -gt $CPU_USR_RHRESHOLD ] && __jdc_cpuhigh_counnt "usr" || echo 0 > "$COUNTER_FILE.usr"
	[ $_sys_cpu -gt $CPU_SYS_RHRESHOLD ] && __jdc_cpuhigh_counnt "sys" || echo 0 > "$COUNTER_FILE.sys"
	[ $_io_cpu -gt $CPU_IO_RHRESHOLD ] && __jdc_cpuhigh_counnt "io" || echo 0 > "$COUNTER_FILE.io"
	[ $_sirq_cpu -gt $CPU_SIRQ_RHRESHOLD ] && __jdc_cpuhigh_counnt "sirq" || echo 0 > "$COUNTER_FILE.sirq"
	[ $_sys_load_average -ge $LOAD_AVERAGE_RHRESHOLD ] && __jdc_cpuhigh_counnt "load_average" || echo 0 > "$COUNTER_FILE.load_average"

	[ -n "$_process_command" ] && {
		#这里不要处理插件的进程
		if __jdc_stringContain 'miniupnpd' "$_process_command"; then /etc/init.d/miniupnpd restart& fi
		if __jdc_stringContain 'hyd' "$_process_command"; then killall -9 hyd& fi
		#if __jdc_stringContain 'jd' "$_process_command"; then killall -9 $_process_command & fi
		if __jdc_stringContain 'ybbplugin' "$_process_command"; then
			[ -z "$(ip a | grep tunYBB)" ] && /etc/init.d/ybbplugin stop
		fi
		if __jdc_stringContain 'sh -c' "$_process_command"; then
			ps | grep "sh -c" | grep -v grep | awk '{print $1}' | xargs kill -9 > /dev/null 2>&1
		fi
	}

	#miniupnpd文件描述符占满时重启进程
	[ $(ls -l /proc/$(pgrep miniupnpd)/fd | wc -l) -gt 100 ] && /etc/init.d/miniupnpd restart &

	if [ $(uci -q get smartqos.qos.mode) -ne 3 -a $(uci -q get smartqos.qos.mode) -ne 0 ];then
		tmp_usr_cpu=$CPU_USR_RHRESHOLD
	else
		tmp_usr_cpu=$((CPU_USR_RHRESHOLD+10))
	fi

	if [ $_usr_cpu -gt $tmp_usr_cpu ] && [ $CPUHIGN_USR_COUNTER -ge 3 ] ;then
		echo 0 > "$COUNTER_FILE.usr"
		logger "$0: _usr_cpu or $_process_command is high!!!!"

		[ $(uci -q get smartqos.qos.mode) -ne 3 -a $(uci -q get smartqos.qos.mode) -ne 0 ] && {
			__jdc_pause_aiec_process
			__jdc_report_event "$EVENT_CPU_CODE" "cpu usage: usr high" "$_usr_cpu% usr"
			return
		}
	fi

	#无终端连接时直接返回,无需处理插件
	[ -n "$(cat /proc/net/arp | grep br-lan)" ] || return

	[ $(uci -q get smartqos.qos.mode) -ne 3 -a $(uci -q get smartqos.qos.mode) -ne 0 ] || {
		T_pids=$(ps | grep -E " T " | grep -v grep | awk '{print $1}')
		for piddd in $T_pids
		do
			kill -cont $piddd
		done

		return
	}

	if [ $_sys_cpu -gt $CPU_SYS_RHRESHOLD ] && [ $CPUHIGN_SYS_COUNTER -ge 3 ] ;then
		echo 0 > "$COUNTER_FILE.sys"
		logger "$0: _sys_cpu $_process_command is high!!!!"
		__jdc_report_event "$EVENT_CPU_CODE" "cpu usage: sys high" "$_sys_cpu% sys"
	fi

	if [ $_io_cpu -gt $CPU_IO_RHRESHOLD -a $CPUHIGN_IO_COUNTER -ge 3 ] || [ $_sys_cpu -gt $CPU_SYS_RHRESHOLD -a $CPUHIGN_SYS_COUNTER -ge 3 ];then
		echo 0 > "$COUNTER_FILE.io"
		logger "$0: _io_cpu is high!!!!"
		#swap;not ax3000
		__jdc_deal_swap_info
		#仅处理双插件情况
		#if [ $(ls /opt/etc/init.d/aiec* | wc -l) -gt 1 ];then
		#	[ "$dev_type" = "jdc-ss01" ] && /opt/etc/init.d/plugin* stop 2>/dev/null
		#fi
		__jdc_pause_aiec_process
		#memory;
		__jdc_get_mem_info _Available_Mem _Cached_Mem
		if [ $_Available_Mem -lt $MEMORY_MemAvailable_RHRESHOLD ] ;then
			if [ $dev_type = $ATH_NEZHA_MODEL -o $dev_type = $ATH_HOUYI_MODEL ];then
				__jdc_restart_pluginall
			fi
		fi
		__jdc_report_event "$EVENT_CPU_CODE" "cpu usage:io high" "$_io_cpu% io"

		return
	fi

	if [ $_sirq_cpu -gt $CPU_SIRQ_RHRESHOLD ] && [ $CPUHIGN_SIRQ_COUNTER -ge 3 ];then
		  echo 0 > "$COUNTER_FILE.sirq"
		  #限制软中断
		  logger "$0: _sirq_cpu is high!!!!"
		  #1 回环设备；非mesh的下,开启防环。
		if [ $(dmesg | grep "own address as source address" | wc -l) -gt 10 ];then
			if [ "$(uci -q get network.lan.stp)" != "1" -a "$(uci -q get system.@system[0].cap_init)" == "0" -a "$(uci -q get system.@system[0].re_init)" == "0" ];then
				uci set network.lan.stp='1' #不关闭了
				uci commit network
				brctl stp br-lan on
			fi
		else
			logger "$0: _sirq_cpu 1111111111 is high!!!!"
			__jdc_deal_session_num "-D"
			__jdc_deal_session_num "-I"
		fi
		  #
		  #2 CPU sirq 高上报
		__jdc_report_event "$EVENT_CPU_CODE" "cpu usage:sirq high" "$_sirq_cpu% sirq"

		return
	fi

	if [ $_sys_load_average -ge $LOAD_AVERAGE_RHRESHOLD ] && [ $CPUHIGN_LOAD_COUNTER -ge 3 ];then
		echo 0 > "$COUNTER_FILE.load_average"
		logger "$0: sys_load_average is high!!!!"
		#swap;not ax3000
		__jdc_deal_swap_info

		#if [ $(ls /opt/etc/init.d/aiec* | wc -l) -gt 1 ];then
		#[ "$dev_type" = "jdc-ss01" ] && /opt/etc/init.d/plugin* stop 2>/dev/null
		#fi
		__jdc_pause_aiec_process
		__jdc_report_event "$EVENT_CPU_CODE" "cpu usage:load_average high" "load_average $_sys_load_average"

		return
	fi

	if [ $CPUHIGN_COUNTER -ge 3 ];then #CPU连续高的第三次
		echo 0 > "$COUNTER_FILE."
		__jdc_pause_aiec_process
		__jdc_report_event "$EVENT_CPU_CODE" "cpu usage:cpu high" "$((100-_idle_cpu))% cpu"
	fi

	#平台配置插件暂停
	if [ "$(uci -q get jd_product.product.plugin_pause)" = "1" ];then
		__jdc_pause_aiec_process all
		#__jdc_report_event "$EVENT_CPU_CODE" "server plugin pause" "server plugin pause"
	fi

	return
}

__jdc_dealcpuinfo_Details "$@"

