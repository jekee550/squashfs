#!/bin/sh
. /lib/functions.sh


common_aiec_version()
{
    echo -n 10005
}

#参数1 插件名
plugin_cgroup_init()
{ 
    [ -z "$1" -o -z "$2" ] && return	
    plugin_name=$1
    id=$2

    mkdir -p /sys/fs/cgroup/plugin/$plugin_name
    echo 0 > /sys/fs/cgroup/plugin/$plugin_name/cpuset.mems
    old_cpus=`cat /sys/fs/cgroup/plugin/cpuset.cpus`
    echo "${old_cpus}" > /sys/fs/cgroup/plugin/$plugin_name/cpuset.cpus

    #first clean the last pid
    for task in `cat /sys/fs/cgroup/plugin/$plugin_name/tasks`
    do
        echo $task > /sys/fs/cgroup/tasks
    done

    echo $id > /sys/fs/cgroup/plugin/$plugin_name/net_cls.classid
}

#参数1 插件名
plugin_set_system_led()
{
    [ -n "$1" ] || return	
    plugin_name=$1

    #configure led
    wan_status="true"
    [ -n "$(uci -q get network.wan.ifname)" ] && {
        wan_status="$(ifstatus wan | jsonfilter -e $.up)"
    }
    wan_connected="$(uci -q get jd_product.network.connected)"
    if [ "$wan_status" = "true" -a "$wan_connected" = "1" ];then
        if [ "$(uci -q get system.led_plugin.default)" = "0" -a "$(. /opt/etc/init.d/$plugin_name && is_running)" = "1" ];then
            #插件在运行，但当前绿灯没亮
            uci -q set system.led_power.default=0
            uci -q set system.led_network.default=0
            uci -q set system.led_plugin.default=1
            /etc/init.d/led start
        elif [ "$(uci -q get system.led_plugin.default)" = "1" -a "$(. /opt/etc/init.d/$plugin_name && is_running)" != "1" ];then
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
                /etc/init.d/led start
            }
        fi
    fi
}

#参数1 iptables/ip6tables
#参数2 插件名
#参数3 markid
#参数4 至少一个classid
plugin_create_statistic_rule()
{
    [ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" ] && return
    ipt=$1
    rule_name=$2
    aiec_file=/opt/etc/firewall.$rule_name
    markid=$3
    shift 3
    id_num=$#

    dev_type=$(. /lib/functions.sh && echo $(product_name) 2>/dev/null)
    if [ "$ipt" = "ip6tables" ];then
        aiec_file=${aiec_file}6
        echo "#!/bin/sh" > $aiec_file
        echo "delete_chain_from_table \"mangle\" ${rule_name} ip6t" >> $aiec_file
    else
        echo "#!/bin/sh" > $aiec_file
        echo "delete_chain_from_table \"mangle\" ${rule_name} ipt" >> $aiec_file
    fi

    [ -z "$($ipt -t mangle -nvxL OUTPUT|grep LOCAL_RQ)" -o -z "$($ipt -t mangle -nvxL|grep "Chain LOCAL_RQ")" ] && {
        wan_interface=$(ip route | grep default | awk '{print $5}')
        $ipt -w -t mangle -N LOCAL_RQ
        $ipt -w -t mangle -D OUTPUT -o $wan_interface -j LOCAL_RQ
        $ipt -w -t mangle -A OUTPUT -o $wan_interface -j LOCAL_RQ
   }
    echo "$ipt -w -t mangle -N ${rule_name}" >> $aiec_file

    for i in $(seq 1 $id_num)
    do
        eval id=\$$i
        [ $id -eq 0 ] && continue

        logger "$rule_name |$i $id"
        echo "$ipt -w -t mangle -D LOCAL_RQ -m cgroup --cgroup $id -j ${rule_name} 2>/dev/null" >> $aiec_file
        echo "$ipt -w -t mangle -A LOCAL_RQ -m cgroup --cgroup $id -j ${rule_name}" >> $aiec_file
    done
    echo "$ipt -w -t mangle -D ${rule_name} -j CONNMARK --set-mark $markid 2>/dev/null" >> $aiec_file
    echo "$ipt -w -t mangle -A ${rule_name} -j CONNMARK --set-mark $markid" >> $aiec_file
    if [ -n "$dev_type" -a "$dev_type" = "RE-CP-03" ] || [ -n "$dev_type" -a "$dev_type" = "RE-CS-06" ];then
        echo "$ipt -w -t mangle -D qos_egress -m connmark --mark $markid -j CLASSIFY --set-class 1:200 2>/dev/null" >> $aiec_file
        echo "$ipt -w -t mangle -A qos_egress -m connmark --mark $markid -j CLASSIFY --set-class 1:200" >> $aiec_file
    else
        echo "$ipt -w -t mangle -D qos_egress -m connmark --mark $markid -j CLASSIFY --set-class 200:0 2>/dev/null" >> $aiec_file
        echo "$ipt -w -t mangle -A qos_egress -m connmark --mark $markid -j CLASSIFY --set-class 200:0" >> $aiec_file
    fi
    sh $aiec_file
}

#迁移主线程和子线程
#参数1 插件名
#参数2 cgroup路径
plugin_cgroup_migrate_task()
{
    [ -z "$1" -o -z "$2" ] && return
    name=$1
    path=$2

    pids=$(ps | grep $name | grep -v grep | awk '{print $1}' | xargs echo)
    for master_pid in $pids
    do
        if [ -z "$(cat $path | grep $master_pid)" ];then
            logger "$pre_prompt $name echo master pid:$master_pid"
            echo $master_pid > $path
        fi

        spids=`ls /proc/$master_pid/task/`
        if [ -z "$spids" ];then
            continue
        fi

        for spid in $spids
        do
            if [ -z "$(cat $path | grep $spid)" ];then
                logger "$pre_prompt $name echo slave pid:$spid"
                echo $spid > $path
            fi
        done
    done
}

#迁移主线程
#参数1 插件名
#参数2 cgroup路径
plugin_cgroup_migrate_task_tgid()
{
    [ -z "$1" -o -z "$2" ] && return
    name=$1
    path=$2

    pids=$(ps | grep $name | grep -v grep | awk '{print $1}' | xargs echo)
    for master_pid in $pids
    do
        if [ -z "$(cat $path | grep $master_pid)" ];then
            logger "$pre_prompt $name echo master pid:$master_pid"
            echo $master_pid > $path
        fi
    done
}

#参数1 缓存路径
#参数2 记录缓存大小文件
plugin_calc_cache()
{
    [ -z "$1" -o -z "$2" ] && return
    path_name=$1
    sizefile=$2
    size=0
    if [ -e $path_name ];then
        size=$(du $path_name -d 0 | awk '{print $1}')
        echo $size > $sizefile
    fi
}

#参数1 异常文件名
plugin_get_sys_fault()
{
    [ -z "$1" ] && return
    sys_codefile=$1
    if [ -e $sys_codefile ];then
        file_mod_time=0

        ret=$(cat $sys_codefile)
        file_mod_time=$(stat $sys_codefile |grep Modify:|awk '{print $2" "$3}'|awk -F . '{print $1}')
        file_mod_time=$(date -d "$file_mod_time" +%s)
        curr_time=$(date +%s)
        dtime=$(expr $curr_time - $file_mod_time)
        #异常码文件超过30分未变化，不使用ret的值
        if [ $dtime -gt 1800 ];then
            #logger "$pre_prompt great 30min"
            ret=0
        fi

        #检查异常码
        if [ $ret != "0" ];then
            return $ret
        fi
    fi

    return 0
}

