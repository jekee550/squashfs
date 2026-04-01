#!/bin/sh

ret_val=1

function usage() {
	cat <<EOF
Usage: $0 <start|stop|restart> [plugin_name]
start or stop pcdn.
EOF
	exit 1
}

function pcdn_ctrl_onoff() {
	for plugin in `ls /opt/etc/init.d/`
	do
		[ "$(uci get jd_plugin.$plugin.plugin_type)" = "aiec" ] && {
			/opt/etc/init.d/$plugin $1
		}
	done
}

function pcdn_ctrl_start() {
	pause=`uci -q get jd_clock.pcdn_pause.pause`
	# APP手动启动智能服务加速后，此pause在C代码中清零
	if [ "$pause" != "0" ]; then
		uci -q set jd_clock.pcdn_pause.pause=0
		uci commit jd_clock
		/usr/sbin/send2agent '{"type":"statusToCloud"}'
	fi
	crontab_str=`crontab -l | grep 'jd_pcdn_control.sh'`
	if [ -n "$crontab_str" ]; then
		crontab -l | grep -v 'jd_pcdn_control.sh' | crontab -
	fi

	pcdn_ctrl_onoff start
}

function pcdn_ctrl_stop() {
	pcdn_ctrl_onoff stop

	pause=`uci -q get jd_clock.pcdn_pause.pause`
	# APP手动启动智能服务加速后，此pause在C代码中清零
	if [ "$pause" != "1" ]; then
		uci -q set jd_clock.pcdn_pause.pause=1
		uci commit jd_clock
		/usr/sbin/send2agent '{"type":"statusToCloud"}'
	fi
}

function pcdn_ctrl_restart() {
	pcdn_ctrl_stop
	pcdn_ctrl_start
}

case "$1" in
	start) pcdn_ctrl_start;;
	stop) pcdn_ctrl_stop;;
	restart) pcdn_ctrl_restart;;
	*) usage;;
esac
