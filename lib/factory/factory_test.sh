. /lib/functions.sh

read_emmc_cid(){
	date=`cat /sys/bus/mmc/drivers/mmcblk/mmc0\:0001/date`
	cid=`cat /sys/bus/mmc/drivers/mmcblk/mmc0\:0001/cid`
	echo "Emmc_cid:$date$cid"
}

read_emmc_size(){
	name=`cat /sys/bus/mmc/drivers/mmcblk/mmc0\:0001/name`
	echo "Emmc_size:$name"
}

led_test_green_on(){
	echo 1 > /sys/class/leds/led_g1/brightness
	echo 0 > /sys/class/leds/led_r1/brightness
	echo 0 > /sys/class/leds/led_b1/brightness
}

led_test_red_on(){
	echo 0 > /sys/class/leds/led_g1/brightness
	echo 1 > /sys/class/leds/led_r1/brightness
	echo 0 > /sys/class/leds/led_b1/brightness
}

led_test_blue_on(){
	echo 0 > /sys/class/leds/led_g1/brightness
	echo 0 > /sys/class/leds/led_r1/brightness
	echo 1 > /sys/class/leds/led_b1/brightness
}

led_test_off(){
	echo 0 > /sys/class/leds/led_g1/brightness
	echo 0 > /sys/class/leds/led_r1/brightness
	echo 0 > /sys/class/leds/led_b1/brightness
}
##格式化分区
format_device(){
	#1.停止定时任务
	/etc/init.d/cron stop
	#2.停止joylink
	/etc/init.d/joylink stop 2>/dev/null
	/etc/init.d/jdc_agent stop
	#3.卸载插件
	for plugin in `ls /opt/etc/init.d/`
	do
		/opt/etc/init.d/$plugin stop
		opkg remove $plugin --force-remove
	done
	#//format /dev/mmcblk0p22,if rootfs_data mount failed
	plugin_fs=$(find_mmc_part "rootfs_data" 2> /dev/null)
	if [ -n "$plugin_fs" -a -z "$(cat /proc/mounts | grep "$plugin_fs")" ];then
		echo yes | mkfs.ext4 $plugin_fs
	fi

	plugin_p=$(find_mmc_part "plugin" 2> /dev/null)
	if [ -n "$plugin_p" ];then
		if [ -n "$(cat /proc/mounts | grep "$plugin_p")" ];then
			umount $plugin_p || {
				echo "format_device failed"
				return 1
			}
		fi
		echo yes | mkfs.ext4 -m 1 $plugin_p
	else
		echo "format_device failed"
		return 1
	fi
	plugin_l=$(find_mmc_part "log" 2> /dev/null)
	if [ -n "$plugin_l" ];then
		if [ -n "$(cat /proc/mounts | grep "$plugin_l")" ];then
			umount $plugin_l || {
				echo "format_device failed"
				return 1
			}
		fi
		echo yes | mkfs.ext4 -m 1 $plugin_l
	else
		echo "format_device failed"
		return 1
	fi
	plugin_s=$(find_mmc_part "storage" 2> /dev/null)
	if [ -n "$plugin_s" ];then
		if [ -n "$(cat /proc/mounts | grep "$plugin_s")" ];then
			umount $plugin_s || {
				echo "format_device failed"
				return 1
			}
		fi
		echo yes | mkfs.ext4 -m 1 -E nodiscard $plugin_s
	else
		echo "format_device failed"
		return 1
	fi
	echo "format_device success"
	return 0
}

mount_emmc(){
	storage_p=$(find_mmc_part "storage" 2> /dev/null)
	if [ -n "$storage_p" ];then
		DEVNAME="$(echo $storage_p | awk -F "/" '{print $3}')"
		emmc_mnt=/mnt/$DEVNAME
		mkdir -p $emmc_mnt
		mount -t ext4 $storage_p $emmc_mnt -o noatime
		if [ -n "$(cat /proc/mounts | grep "$storage_p")" ];then
			echo "mount_emmc success"
		else
			echo "mount_emmc failed"
		fi
	else
		echo "mount_emmc failed"
	fi
}

