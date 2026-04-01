#!/bin/sh

. /lib/config/uci.sh

BIN_DIR=/opt/jd-firmware
download_sysupgrade_file() {
	cur_version=`cat /rom/etc/openwrt_version`
	new_version="$(uci_get jd_product.upgrade.version)"
	logger -s "upgrade: cur_version=$cur_version , new_version=$new_version"
	if [ "$cur_version" = "$new_version" ]; then
	{
		logger -s "upgrade: version is eq, version=$cur_version, do not sysupgrade!"
		exit;
	}
	fi
	new_md5="$(uci_get jd_product.upgrade.md5)"
	echo "md5=$new_md5"
	get_file_md5=`md5sum $BIN_DIR/firmware_$new_version.bin |awk '{print $1}'`
	if [ "$new_md5" != "$get_file_md5" ]; then
	{
		logger -s "upgrade: md5 is not eq! exit!, new_md5=$new_md5, get_file_md5=$get_file_md5"
		exit;
	}
	fi
	#check telnet switch
	telnets="$(factory_hm info | grep telnet | awk -F "telnet=" '{print $2}')"
	[ "$telnets" = "1" ] && factory_hm info telnet 0

	#检查crontab是否被用户修改
	#crontab_m="$(crontab -l | grep -v reotate_log.sh | grep -v jd_reboot_plan.sh | grep -v jd_wifi_plan.sh | grep -v jd_online_upgrade.sh | grep -v jd_screen_plan.sh | grep -v ac_ctl_cron.sh)"
	#[ -n "$crontab_m" ] && cp -f /rom/etc/crontabs/root /etc/crontabs

	[ -n "$(cat /etc/hosts | grep "ipes-tus.iqiyi.com")" ] && cp -f /rom/etc/hosts /etc

	logger -s "upgrade: get upgrade file is OK! md5: $get_file_md5  reboot system"
	uci set jd_product.upgrade.upgrade_mask='1'
	uci commit jd_product
	/sbin/jdc_logbackup -s
	sync && reboot && sleep 1 && reboot -f &
	sleep 10 && echo c > /proc/sysrq-trigger
}

download_sysupgrade_file

