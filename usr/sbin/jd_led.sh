#!/bin/sh
# (C) 2024 openwrt.org

. /lib/functions.sh

ACTION=$1
NAME=$2
COMMIT_FLAG=0

function usage() {
	cat <<EOF
Usage: $0 <set|clear> [power|network|plugin]
set led brightness.
EOF
	exit 1
}

control_led() {
	local section_name=$1
	local name
	local sysfs
	local current_status=0
	config_get name $1 name
	config_get sysfs $1 sysfs
	[ ! -e "/sys/class/leds/${sysfs}" ] && return

	logger -s "[jd_led.sh] : section=$section_name, name=$name, sysfs=$sysfs"
	if [ "$name" = "$NAME" -o "$sysfs" = "$NAME" ]; then
		if [ "$ACTION" = "set" ]; then
			current_status=1
			logger -s "[jd_led.sh] : $ACTION $name"
		else
			logger -s "[jd_led.sh] : clear $name"
		fi
	else
		logger -s "[jd_led.sh] : clear $name"
	fi
	echo $current_status >/sys/class/leds/${sysfs}/brightness

	last_status=$(uci -q get system.$section_name.default)
	[ "$last_status" != "$current_status" ] && {
		uci -q set system.$section_name.default=$current_status
		COMMIT_FLAG=1
	}

}

process_led_command() {
	[ "$NAME" != "power" -a  "$NAME" != "network" -a  "$NAME" != "plugin" ] && {
		usage
		exit 0
	}

	COMMIT_FLAG=0
	logger -s "[jd_led.sh] : ACTION=$ACTION, NAME=$NAME"
	config_load system
	config_foreach control_led led
	[ $COMMIT_FLAG = 1 ] && {
		uci commit system
		logger -s "[jd_led.sh] : uci commit system"
		}
}

case "$1" in
	set) process_led_command;;
	clear) process_led_command;;
	*) usage;;
esac
