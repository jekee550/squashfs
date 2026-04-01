#!/bin/sh

version=0005

if [ -e /lib/ipq806x.sh ];then
	. /lib/ipq806x.sh
	dev_type="$(ipq806x_product_name)"
elif [ -e /lib/ramips.sh ];then
	. /lib/ramips.sh
	dev_type="$(ramips_product_name)"
else
	. /lib/functions.sh
	dev_type="$(product_name)"
fi

smartqos_mod=$(uci get smartqos.qos.mode 2>/dev/null)
[ -z "$smartqos_mod" ] && smartqos_mod=1

do_resource_limit()
{
	if [ $smartqos_mod -eq 3 ];then
		echo 1-3 > /sys/fs/cgroup/plugin/cpuset.cpus
		echo 1-3 > /sys/fs/cgroup/docker/cpuset.cpus
	else
		echo 2-3 > /sys/fs/cgroup/plugin/cpuset.cpus
		echo 2-3 > /sys/fs/cgroup/docker/cpuset.cpus
	fi

	#if [ $smartqos_mod -eq 1 -o $smartqos_mod -eq 2 ];then
	#	#plugin cpu占用最高80%
	#	echo 80000 > /sys/fs/cgroup/plugin/cpu.cfs_quota_us
	#	echo 80000 > /sys/fs/cgroup/docker/cpu.cfs_quota_us
	#else
	#	echo -1 > /sys/fs/cgroup/plugin/cpu.cfs_quota_us
	#	echo -1 > /sys/fs/cgroup/docker/cpu.cfs_quota_us
	#fi

	#Athena
	if [ "$dev_type" = "RE-SS-02" ];then
		if [ "$(uci get system.@system[0].cap_init)" = "1" -o "$(uci get system.@system[0].re_init)" = "1" ];then
			echo 350M > /sys/fs/cgroup/plugin/memory.soft_limit_in_bytes
			echo 400M > /sys/fs/cgroup/plugin/memory.limit_in_bytes
			#echo 650M > /sys/fs/cgroup/plugin/memory.memsw.limit_in_bytes 2>/dev/null
			[ -d /sys/fs/cgroup/docker ] && {
				echo 350M > /sys/fs/cgroup/docker/memory.soft_limit_in_bytes
				echo 400M > /sys/fs/cgroup/docker/memory.limit_in_bytes
				#echo 650M > /sys/fs/cgroup/docker/memory.memsw.limit_in_bytes 2>/dev/null
			}
		elif [ $smartqos_mod -eq 3 ];then
			echo 500M > /sys/fs/cgroup/plugin/memory.soft_limit_in_bytes
			echo 550M > /sys/fs/cgroup/plugin/memory.limit_in_bytes
			#echo 850M > /sys/fs/cgroup/plugin/memory.memsw.limit_in_bytes 2>/dev/null
			[ -d /sys/fs/cgroup/docker ] && {
				echo 500M > /sys/fs/cgroup/docker/memory.soft_limit_in_bytes
				echo 550M > /sys/fs/cgroup/docker/memory.limit_in_bytes
				#echo 850M > /sys/fs/cgroup/docker/memory.memsw.limit_in_bytes 2>/dev/null
			}
		else
			echo 450M > /sys/fs/cgroup/plugin/memory.soft_limit_in_bytes
			echo 500M > /sys/fs/cgroup/plugin/memory.limit_in_bytes
			#echo 700M > /sys/fs/cgroup/plugin/memory.memsw.limit_in_bytes 2>/dev/null
			[ -d /sys/fs/cgroup/docker ] && {
				echo 450M > /sys/fs/cgroup/docker/memory.soft_limit_in_bytes
				echo 500M > /sys/fs/cgroup/docker/memory.limit_in_bytes
				#echo 700M > /sys/fs/cgroup/docker/memory.memsw.limit_in_bytes 2>/dev/null
			}
		fi
	#Arthur
	else
		if [ "$(uci get system.@system[0].cap_init)" = "1" -o "$(uci get system.@system[0].re_init)" = "1" ];then
			echo 100M > /sys/fs/cgroup/plugin/memory.soft_limit_in_bytes
			echo 150M > /sys/fs/cgroup/plugin/memory.limit_in_bytes
			#echo 350M > /sys/fs/cgroup/plugin/memory.memsw.limit_in_bytes 2>/dev/null
			[ -d /sys/fs/cgroup/docker ] && {
				echo 100M > /sys/fs/cgroup/docker/memory.soft_limit_in_bytes
				echo 150M > /sys/fs/cgroup/docker/memory.limit_in_bytes
				#echo 350M > /sys/fs/cgroup/docker/memory.memsw.limit_in_bytes 2>/dev/null
			}
		elif [ $smartqos_mod -eq 3 ];then
			echo 150M > /sys/fs/cgroup/plugin/memory.soft_limit_in_bytes
			echo 200M > /sys/fs/cgroup/plugin/memory.limit_in_bytes
			#echo 350M > /sys/fs/cgroup/plugin/memory.memsw.limit_in_bytes 2>/dev/null
			[ -d /sys/fs/cgroup/docker ] && {
				echo 150M > /sys/fs/cgroup/docker/memory.soft_limit_in_bytes
				echo 200M > /sys/fs/cgroup/docker/memory.limit_in_bytes
				#echo 350M > /sys/fs/cgroup/docker/memory.memsw.limit_in_bytes 2>/dev/null
			}
		else
			echo 100M > /sys/fs/cgroup/plugin/memory.soft_limit_in_bytes
			echo 150M > /sys/fs/cgroup/plugin/memory.limit_in_bytes
			#echo 350M > /sys/fs/cgroup/plugin/memory.memsw.limit_in_bytes 2>/dev/null
			[ -d /sys/fs/cgroup/docker ] && {
				echo 100M > /sys/fs/cgroup/docker/memory.soft_limit_in_bytes
				echo 150M > /sys/fs/cgroup/docker/memory.limit_in_bytes
				#echo 350M > /sys/fs/cgroup/docker/memory.memsw.limit_in_bytes 2>/dev/null
			}
		fi

	fi
}


if [ -e /tmp/.bootdone ];then
	for plugin in `ls /opt/etc/init.d/`
	do
		[ "$(uci get jd_plugin.$plugin.plugin_type)" = "aiec" ] && {
			/opt/etc/init.d/$plugin stop
		}
	done

	/sbin/fw_clean_cmd.sh firewall

	do_resource_limit

	for plugin in `ls /opt/etc/init.d/`
	do
		[ "$(uci get jd_plugin.$plugin.plugin_type)" = "aiec" ] && {
			/opt/etc/init.d/$plugin start &
		}
	done
else
	do_resource_limit
fi
