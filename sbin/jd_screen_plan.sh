#!/bin/sh
# Copyright (C) 2006 OpenWrt.org

usage() {
	cat <<EOF
Usage: $0 [start|stop]
start or stop screen plan configuration.
EOF
	exit 1
}

timingswitch=

check_timingswitch() {
	once_flag=`crontab -l|grep "jd_screen_plan.sh"|wc -l`
	echo "once_flag = $once_flag, timingswitch = $timingswitch"
	if [ $once_flag = 0 -a -n "$timingswitch" -a "$timingswitch" != 0 ]
	then
		echo "save timingswitch = 0"
		uci -q set system.screen_switch.timingswitch=0
		uci commit
	fi
}

check_repeat() {
	# 判断 timingswitch 是否不为0，如果为0，则新版本定时器生效，
	# 防止异常删除新版本设置的定时器
	timingswitch=`uci -q get system.screen_switch.timingswitch`
	repeat=`uci -q get system.screen_switch.timingswitch_repeat`
	echo "repeat = $repeat, timingswitch = $timingswitch"
	if [ -n "$repeat" -a -n "$timingswitch" -a "$repeat" = 0 -a "$timingswitch" != 0 ]
	then
		crontab -l | grep -v "jd_screen_plan.sh $1" | crontab -
		echo "clear crontab : jd_screen_plan.sh $1"
	fi
}

screen_start() {
	check_repeat start

	check_timingswitch

	led_mode=`uci -q get system.screen_switch.mode`
	[ "$led_mode" = "1" ] && {
		logger -s "[led_plan] : manual mode, exit screen_start"
		return
	}

	screen_tool 15 on

	#echo "wifi plan start"
}

screen_stop() {
	check_repeat stop

	check_timingswitch

	led_mode=`uci -q get system.screen_switch.mode`
	[ "$led_mode" = "1" ] && {
		logger -s "[led_plan] : manual mode, exit screen_stop"
		return
	}

	screen_tool 15 off

	#echo "wifi plan stop"
}

case "$1" in
	start) screen_start;;
	stop) screen_stop;;
	*) usage;;
esac
