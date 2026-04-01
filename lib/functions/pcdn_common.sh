#!/bin/sh
. /lib/functions.sh
. /lib/ipq806x.sh

#A 0x100001 mark 901
#B 0x100002 mark 902
#E 0x100003 mark 903
#I 0x100004 mark 904 
#J 0x100005 mark 905
#H 0x100006 mark 906
#D 0x100007 mark 907
#G 0x100008 mark 908
#DS 0x100009 mark 909
get_classid()
{
	name=$1
	if [ $name = "aiecpluginA" -o $name = "aiecpluginextA" ];then
		echo "0x100001 901"	
	elif [ $name = "aiecpluginB" ];then
		echo "0x100002 902"	
	elif [ $name = "aiecpluginD" ];then
		echo "0x100007 907"	
	elif [ $name = "aiecpluginE" ];then
		echo "0x100003 903"	
	elif [ $name = "aiecpluginG" ];then
		echo "0x100008 908"	
	elif [ $name = "aiecpluginH" ];then
		echo "0x100006 906"	
	elif [ $name = "aiecpluginI" ];then
		echo "0x100004 904"	
	elif [ $name = "aiecpluginJ" ];then
		echo "0x100005 905"	
	elif [ $name = "aiecpluginDS" ];then
		echo "0x100009 909"	
	fi
}

path_get()
{
	[ "$(uci -q get jd_clock.pcdn_pause.pause)" != "1" ] || return
	#$2:"","inter","exter"
	config_get part $1 part
	[ -z "$part" ] && config_get part $1 name
	config_get mode $1 mode
	config_get part_size $1 part_size
	[ -n "$(echo $part | grep mmcblk)" -a -z "$mode" ] && {
		[ -e /mnt/$part/.jdc_disk_mode ] && mode=`cat /mnt/$part/.jdc_disk_mode`
		[ -z "$mode" ] && mode='pcdn'
	}

	[ -n "$(echo $part | grep sd)" -a -z "$mode" ] && {
		[ -e /mnt/$part/.jdc_disk_mode ] && mode=`cat /mnt/$part/.jdc_disk_mode`
		[ -z "$mode" ] && mode='samba'
	}

	if [ -n "$(echo $part | grep mmcblk)" -a "$mode" = "pcdn" ];then
		int_part=$part
		int_size=$part_size
	elif [ -n "$(echo $part | grep sd)" -a "$mode" = "pcdn" ];then
		ext_part=$part
		ext_size=$part_size
	fi
}

get_pcdn_path()
{
	#$1:"","inter","exter"
	#$2:"","max","min","fixed"
	int_part=
	int_size=
	ext_part=
	ext_size=
	vhd_enable=
	storage_p=$(find_mmc_part "storage" 2> /dev/null)
	[ -n "$storage_p" ] && DEVNAME="$(echo $storage_p | awk -F "/" '{print $3}')"
	[ -n "$storage_p" ] && [ -z "$(cat /proc/mounts | grep "$storage_p")" -o -z "$(uci -q get samba.$DEVNAME.part_size)" ] && {
		[ $(cat /etc/init.d/mount_opt | wc -l) -eq 0 ] && cp /rom/etc/init.d/mount_opt /etc/init.d/
		. /etc/init.d/mount_opt
		mount_opt_data
	}

	config_load samba
	type=$1
	#[ -z "$type" ] && type='inter'
	[ -n "$(uci -q get jd_plugin.jdcvhd_config)" ] && vhd_enable="$(uci -q get jd_plugin.vhd_inter.enable)"
	[ -z "$vhd_enable" ] && {
		[ -n "$(cat /proc/mounts | grep "/dev/loop0")" -o -n "$(cat /proc/mounts | grep "/dev/loop1")" ] && vhd_enable='1'
	}
	[ -z "$vhd_enable" ] && vhd_enable='0'

	config_foreach path_get sambashare
	if [ -z "$type" ];then
		if [ -z "$ext_size" -a -n "$int_part" ];then
			if [ "$vhd_enable" = "1" ];then
				if [ -z "$2" -o "$2" = "max" ];then
					echo "loop1"
				elif [ "$2" = "min" ];then
					echo "loop0"
				elif [ "$2" = "fixed" ];then
					echo "$int_part"
				fi
			else
				echo "$int_part"
			fi
		elif [ -z "$int_size" -a -n "$ext_part" ];then
			echo "$ext_part"
		elif [ -n "$ext_size" -a -n "$int_size" ];then
			if [ "$vhd_enable" = "1" ];then
				vhd_percent="$(uci -q get jd_plugin.vhd_inter.percent)"
				[ -z "$vhd_percent" ] && vhd_percent='51'
				if [ -z "$2" -o "$2" = "max" ];then
					max_size=$(($int_size*$vhd_percent/100))
					if [ $ext_size -gt $max_size ];then
						echo "$ext_part"
					else
						echo "loop1"
					fi
				elif [ "$2" = "min" ];then
					min_percent=$((100-$vhd_percent))
					min_size=$(($int_size*$min_percent/100))
					if [ $ext_size -gt $min_size ];then
						echo "$ext_part"
					else
						echo "loop0"
					fi
				elif [ "$2" = "fixed" ];then
					echo "$int_part"
				fi
			else
				if [ $ext_size -gt $int_size ];then
					echo "$ext_part"
				else
					echo "$int_part"
				fi
			fi
		fi
	elif [ "$type" = "inter" -a -n "$int_part" ];then
		if [ "$vhd_enable" = "1" ];then
			if [ -z "$2" -o "$2" = "max" ];then
				echo "loop1"
			elif [ "$2" = "min" ];then
				echo "loop0"
			elif [ "$2" = "fixed" ];then
				echo "$int_part"
			fi
		else
			echo "$int_part"
		fi
	elif [ "$type" = "exter" -a -n "$ext_part" ];then
		echo "$ext_part"
	fi
}

pcdn_stop()
{
	plugin_running='0'
	for plugin in `ls /opt/etc/init.d/ | grep ^aiecplugin`
	do
		if [ "$(/opt/etc/init.d/$plugin is_running)" = "1" ];then
			plugin_running='1'
			break
		fi
	done

	netstate=`uci get jd_product.network.connected`
	if [ $netstate == 1 ]; then
		wan_status="true"
		[ -n "$(uci -q get network.wan.ifname)" ] && {
			wan_status="$(ifstatus wan | jsonfilter -e $.up)"
		}
		if [ "$wan_status" = "true" -a "$plugin_running" = "1" -a "$(uci -q get system.led_plugin.default)" != "1" ];then
			uci -q set system.led_power.default=0
			uci -q set system.led_network.default=0
			uci -q set system.led_plugin.default=1
			#uci commit system
			/etc/init.d/led start
		elif [ "$wan_status" = "true" -a "$plugin_running" = "0" -a "$(uci -q get system.led_network.default)" != "1" ];then
			uci -q set system.led_power.default=0
			uci -q set system.led_network.default=1
			uci -q set system.led_plugin.default=0
			#uci commit system
			/etc/init.d/led start
		fi
	elif [ $netstate == 0 -a "$(uci -q get system.led_power.default)" != "1" ]; then
		uci -q set system.led_power.default=1
		uci -q set system.led_network.default=0
		uci -q set system.led_plugin.default=0
		#uci commit system
		/etc/init.d/led start
	fi
	
	delete_chain_from_table mangle ${NAME}
	delete_chain_from_table mangle ${NAME} ip6t
	rm -f /opt/etc/firewall.${NAME}
	rm -f /opt/etc/firewall.${NAME}6
	#/etc/init.d/smart_qos stop
	#sleep 1
	#/etc/init.d/smart_qos start
}

#格式化硬盘，插拔硬盘时调用，检查需要启动/停止的插件
#参数1：分区名:sda1/mmcblk0p11
#参数2：start/stop
jdcpcdn_check_start(){
	[ -n "$1" ] || return
	[ -n "$2" ] || return
	[ -n "$(uci -q get jd_plugin.jdcvhd_config)" ] && vhd_enable="$(uci -q get jd_plugin.vhd_inter.enable)"
	[ -z "$vhd_enable" ] && {
		[ -n "$(cat /proc/mounts | grep "/dev/loop0")" -o -n "$(cat /proc/mounts | grep "/dev/loop1")" ] && vhd_enable='1'
	}

	if [ "$2" = "start" ];then
		storage_p=$(find_mmc_part "storage" 2> /dev/null)
		if [ -n "$storage_p" -a "$(ipq806x_product_name)" = "jdc-ss01" -a -n "$(cat /proc/mounts | grep $storage_p)" ];then
			DEVNAME="$(echo $storage_p | awk -F "/" '{print $3}')"
			if [ -e /mnt/$DEVNAME/.swap ]; then
				swapon /mnt/$DEVNAME/.swap || {
					rm /mnt/$DEVNAME/.swap
					dd if=/dev/zero of=/mnt/$DEVNAME/.swap bs=256k count=2048 && mkswap /mnt/$DEVNAME/.swap && swapon /mnt/$DEVNAME/.swap &
				}
			else
				dd if=/dev/zero of=/mnt/$DEVNAME/.swap bs=256k count=2048 && mkswap /mnt/$DEVNAME/.swap && swapon /mnt/$DEVNAME/.swap &
			fi
		fi

		[ "x" = "$vhd_enable" ] && /opt/etc/init.d/jdcvhd_config start
		if [ -n "$(echo $1 | grep mmcblk)" -a -n "$vhd_enable" -a "$vhd_enable" = "0" ];then
			#2.内置存储边缘计算切换为本地网盘时调用
			if [ -z "$(get_pcdn_path inter fixed)" ];then
				for plugin in `ls /opt/etc/init.d/`
				do
					[ "$(uci -q get jd_plugin.$plugin.plugin_type)" = "aiec" ] || continue
					[ "$(/opt/etc/init.d/$plugin is_running)" != "1" ] && {
						timeout 300 /opt/etc/init.d/$plugin restart
					}
				done
			else
				#内置存储本地网盘切换为边缘计算时调用
				/opt/etc/init.d/jdcvhd_config start
			fi
		else
			for plugin in `ls /opt/etc/init.d/`
			do
				[ "$(uci -q get jd_plugin.$plugin.plugin_type)" = "aiec" ] || continue
				storage_type="$(. /opt/etc/init.d/$plugin && echo $STORAGE_TYPE)"
				#1.插上硬盘且为pcdn模式或从本地网盘切换到边缘计算
				#2.拔出硬盘或从边缘计算切换到本地网盘
				if [ "$(get_pcdn_path $storage_type)" = "$1" -o "$(/opt/etc/init.d/$plugin is_running)" != "1" ];then
					timeout 300 /opt/etc/init.d/$plugin restart
				fi
			done
		fi
	elif [ "$2" = "stop" ];then
		if [ -n "$(echo $1 | grep mmcblk)" -a -n "$vhd_enable" -a "$vhd_enable" = "1" ];then
			#1.内置存储边缘计算切换为本地网盘时调用
			timeout 300 /opt/etc/init.d/jdcvhd_config stop
			pcdn_stop
		else
			for plugin in `ls /opt/etc/init.d/`
			do
				[ "$(uci -q get jd_plugin.$plugin.plugin_type)" = "aiec" ] || continue
				disk_path="$(. /opt/etc/init.d/$plugin && echo $DISK_PATH)"
				if [ "$disk_path" = "/mnt/$1" ] || [ -n "$(echo $disk_path | grep loop)" -a -n "$(echo $1 | grep mmcblk)" ];then
					timeout 300 /opt/etc/init.d/$plugin stop
					pcdn_stop
				fi
			done
		fi
	fi
}

#parameter1:plugin name:tencent_booster
#size:15G
plugin_occupy_size() {
	[ -z "$1" ] && return
	[ -z "$2" -o $2 -lt 5 ] && return
	[ ! -e /opt/etc/init.d/$1 ] && return
	storage_type="$(. /opt/etc/init.d/$1 && echo $STORAGE_TYPE)"
	[ -z "$storage_type" ] && storage_type=""
	part="$(get_pcdn_path "$storage_type" "fixed")"
	[ -z "$part" ] && return

	avail_size=`df | grep /dev/$part | head -1 | awk '{print $4}'`
	avail_size=$(($avail_size/1024/1024))

	[ $avail_size -ge $2 ] && return

	for plugin in `ls /opt/etc/init.d/ | grep ^aiecplugin`
	do
		storage_type="$(. /opt/etc/init.d/$plugin && echo $STORAGE_TYPE)"
		[ -z "$storage_type" ] && storage_type=""
		part_tmp="$(get_pcdn_path "$storage_type" "fixed")"
		[ -n "$part_tmp" -a "$part_tmp" = "$part" ] && {
			/opt/etc/init.d/$plugin reset
			break
		}
	done
}

network_state_change_set_led()
{
	[ -n "$1" ] || return	
	netstate=$1

	#检测是否有插件运行
	plugin_running='0'
	for plugin in `ls /opt/etc/init.d/ | grep ^aiecplugin`
	do
		if [ "$(timeout 2 /opt/etc/init.d/$plugin is_running)" = "1" ];then
			plugin_running='1'
			break
		fi
	done

	if [ $netstate == 1 ]; then
		#网络状态变为已连接
		wan_status="true"
		[ -n "$(uci -q get network.wan.ifname)" ] && {
			wan_status="$(ifstatus wan | jsonfilter -e $.up)"
		}
		if [ "$wan_status" = "true" -a "$plugin_running" = "1" -a "$(uci -q get system.led_plugin.default)" != "1" ];then
			#wan口状态为true，且插件正常运行，绿灯
			uci -q set system.led_power.default=0
			uci -q set system.led_network.default=0
			uci -q set system.led_plugin.default=1
			#uci commit system
			/etc/init.d/led start
		elif [ "$wan_status" = "true" -a "$plugin_running" = "0" -a "$(uci -q get system.led_network.default)" != "1" ];then
			#wan口状态为true，插件未运行，蓝灯
			uci -q set system.led_power.default=0
			uci -q set system.led_network.default=1
			uci -q set system.led_plugin.default=0
			#uci commit system
			/etc/init.d/led start
		fi
	elif [ $netstate == 0 -a "$(uci -q get system.led_power.default)" != "1" ]; then
		#网络状态变为断开，点灯为红色
		if [ "$(uci -q get system.@system[0].re_init)" == "1" ]; then
			kill -USR2 $(pidof udhcpc) ;kill -USR1 $(pidof udhcpc)
		fi
		uci -q set system.led_power.default=1
		uci -q set system.led_network.default=0
		uci -q set system.led_plugin.default=0
		#uci commit system
		/etc/init.d/led start
	fi
}

plugin_set_led()
{
	[ -n "$1" ] || return	
	pro_name=$1

    #configure led
    wan_status="true"
    [ -n "$(uci -q get network.wan.ifname)" ] && {
        wan_status="$(ifstatus wan | jsonfilter -e $.up)"
    }
    wan_connected="$(uci -q get jd_product.network.connected)"
    if [ "$wan_status" = "true" -a "$wan_connected" = "1" ];then
        if [ "$(uci -q get system.led_plugin.default)" = "0" -a -n "$(pgrep -x $pro_name)" ];then
            #插件在运行，但当前绿灯没亮
            uci -q set system.led_power.default=0
            uci -q set system.led_network.default=0
            uci -q set system.led_plugin.default=1
            #uci commit system.led_power.default
			#uci commit system.led_network.default
			#uci commit system.led_plugin.default
            /etc/init.d/led start
        elif [ "$(uci -q get system.led_plugin.default)" = "1" -a -z "$(pgrep -x $pro_name)" ];then
            #插件未运行，但绿灯亮
            plugin_running='0'
            for plugin in `ls /opt/etc/init.d/ | grep ^aiecplugin`
            do
                if [ "$(/opt/etc/init.d/$plugin is_running)" = "1" ];then
                    plugin_running='1'
                    break
                fi
            done
            [ "$plugin_running" = "0" ] && {
                uci -q set system.led_power.default=0
                uci -q set system.led_network.default=1
                uci -q set system.led_plugin.default=0
				#uci commit system.led_power.default
				#uci commit system.led_network.default
				#uci commit system.led_plugin.default
                /etc/init.d/led start
            }
        fi
    fi
    #临时文件大于2k时保存提交
    [ -f /tmp/.uci/system ] && [ $(stat -c %s /tmp/.uci/system) -gt 2048 ] && uci commit
}

