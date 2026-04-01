#!/bin/sh
/sbin/jdc_logbackup -s
repeat=`uci -q get jd_clock.reboot_plan.repeat_plan`
touch /etc/openwrt_release

if [ $repeat = 0 ]
then
	crontab -l | grep -v 'jd_reboot_plan.sh' | crontab -
	uci -q set jd_clock.reboot_plan.enable=0
	uci commit jd_clock
fi

reboot && sleep 1 && reboot -f &
sleep 10 && echo c > /proc/sysrq-trigger

