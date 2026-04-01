#!/bin/sh

ret_val=1

function usage() {
	cat <<EOF
Usage: $0 [start|stop|restart]
start or stop led.
EOF
	exit 1
}

function led_start() {
	led_mode=`uci -q get system.led_switch.mode`
	[ "$led_mode" = "1" ] && {
		logger -s "[led_plan] : manual mode, exit led_start"
		return
	}

	led_switch=`uci -q get system.led_switch.enable`
	if [ "$led_switch" != "1" ]; then
		uci -q set system.led_switch.enable=1
		uci -q set jdc_ezmesh.ezmesh.user_turns_on_led=1
		uci commit system
		uci commit jdc_ezmesh
	fi
	/etc/init.d/led start
}

function led_stop() {
	led_mode=`uci -q get system.led_switch.mode`
	[ "$led_mode" = "1" ] && {
		logger -s "[led_plan] : manual mode, exit led_stop"
		return
	}

	led_switch=`uci -q get system.led_switch.enable`
	if [ "$led_switch" != "0" ]; then
		uci -q set system.led_switch.enable=0
		uci -q set jdc_ezmesh.ezmesh.user_turns_on_led=0
		uci commit system
		uci commit jdc_ezmesh
	fi
	/etc/init.d/led stop
}

function led_restart() {
	led_stop
	led_start
}

case "$1" in
	start) led_start;;
	stop) led_stop;;
	restart) led_restart;;
	*) usage;;
esac
