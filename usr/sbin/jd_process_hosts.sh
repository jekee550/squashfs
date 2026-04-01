#!/bin/sh

hosts_path=/etc
current_hosts=${hosts_path}/hosts
custom_hosts=${hosts_path}/custom_hosts
rom_hosts=/rom${current_hosts}

# /etc/hosts存在 && 与/rom/etc/hosts的md5相同，
# 则用/etc/hosts覆盖/etc/custom_hosts,
# 用/rom/etc/hosts覆盖/etc/hosts
if [ -e $current_hosts ] ;then
	md5_1=$(md5sum $current_hosts | cut -d " " -f1)
	md5_2=$(md5sum $rom_hosts | cut -d " " -f1)
	if [ "$md5_2" != "$md5_1" ] ;then
		[ ! -e $custom_hosts ] && {
			cp -f $current_hosts $custom_hosts
		}
		cp -f $rom_hosts $current_hosts
	fi
else
# /etc/hosts不存在，则用/rom/etc/hosts覆盖/etc/hosts
	cp -f $rom_hosts $current_hosts
fi
