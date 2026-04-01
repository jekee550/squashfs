#!/bin/sh
# Copyright (C) 2006 OpenWrt.org

usage() {
	cat <<EOF
Usage: $0 [start|stop]
start or stop wifi plan configuration.
EOF
	exit 1
}

# 雅典娜: 接口与WiFi频段对应
# ath0      5GHz
# ath1    2.4GHz
# ath2    5.2GHz

need_commit=0
enable=

# 重载WiFi配置
wifi_reload_port() {
	logger -s "[wifi_plan] : arg1 = $1, arg2 = $2, arg3 = $3"
	wifi_switch=`uci -q get jd_clock.wifi_plan.$2`
	current_switch=`uci -q get wireless.$1.disabled`
	logger -s "[wifi_plan] : wifi_switch = $wifi_switch, current_switch = $current_switch"
	if [ -z "$wifi_switch" -o "$wifi_switch" == "1" ]; then
		if [ "$current_switch" != "0" ]; then
			uci -q set wireless.$1.disabled=0
			uci commit wireless
			logger -s "[wifi_plan] : --->> wifi up $3 $1"
			# 仅重启从关闭到开启的wifi
			wifi up $3 $1
		fi
	fi
}

wifi_reload_environment() {
	wifi_reload_port ath0 5g wifi0
	wifi_reload_port ath1 2_4g wifi1
	if [ "$1" == "RE-SS-02" ]; then
		wifi_reload_port ath2 5_2g wifi2
	fi
}

check_enable() {
	once_flag=`crontab -l|grep "jd_wifi_plan.sh"|wc -l`
	logger -s "[wifi_plan] : once_flag = $once_flag, enable = $enable"
	if [ $once_flag = 0 -a "$enable" != "0" ]; then
		logger -s "[wifi_plan] : save enable = 0"
		uci -q set jd_clock.wifi_plan.enable=0
		uci commit jd_clock
	fi
}

check_repeat() {
	# 判断老版本 enable 是否不为0，如果为0，则新版本定时器生效，
	# 防止异常删除新版本设置的定时器
	enable=`uci -q get jd_clock.wifi_plan.enable`
	repeat=`uci -q get jd_clock.wifi_plan.repeat`
	week=`uci -q get jd_clock.wifi_plan.week`
	logger -s "[wifi_plan] : repeat = $repeat, enable = $enable"
	if [ "$repeat" = "0" -a "$week" = "0" -a "$enable" != "0" ]; then
		crontab -l | grep -v "jd_wifi_plan.sh $1" | crontab -
		logger -s "[wifi_plan] : clear crontab : jd_wifi_plan.sh $1"
	fi
}

check_is_mesh() {
	re_init=`uci -q get system.@system[0].re_init`
	cap_init=`uci -q get system.@system[0].cap_init`
	logger -s "[wifi_plan] : re_init = $re_init, cap_init = $cap_init"
	if [ "$re_init" = "1" -o "$cap_init" = "1" ]; then
		logger -s "[wifi_plan] : mesh mode"
		return 0
	fi

	logger -s "[wifi_plan] : router mode"
	return 1
}

# 检测是否极限积分模式
check_is_ultra_credit() {
	mode=`uci -q get smartqos.qos.mode`
	if [ "$mode" = "3" ]; then
		logger -s "[wifi_plan] : ultra credit mode"
		return 0
	fi

	return 1
}

wifi_start() {

	check_is_ultra_credit && return

	product=`. /lib/ipq806x.sh && ipq806x_product_name`

	wifi_reload_environment $product

	check_repeat start

	check_enable

	#echo "wifi plan start"
	# logger -s "wifi plan start"
}

wifi_stop() {

	check_is_mesh && return

	check_is_ultra_credit && return

	product=`. /lib/ipq806x.sh && ipq806x_product_name`

	uci -q set wireless.ath0.disabled=1
	uci -q set wireless.ath1.disabled=1
	if [ "$product" == "RE-SS-02" ]; then
		uci -q set wireless.ath2.disabled=1
	fi
	uci commit wireless

	wifi up wifi0 ath0
	wifi up wifi1 ath1
	[ "$product" == "RE-SS-02" ] && wifi up wifi2 ath2


	check_repeat stop

	check_enable

	#echo "wifi plan stop"
	# logger -s "wifi plan stop"
}

case "$1" in
	start) wifi_start;;
	stop) wifi_stop;;
	*) usage;;
esac
