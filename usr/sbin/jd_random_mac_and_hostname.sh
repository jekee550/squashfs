#!/bin/sh

model=
raw_hostname=
random_mac=
random_hostname=

#获取产品型号
get_product_name(){
    local model_name=
    if [ -e "/lib/ipq806x.sh" ]; then
        model_name=$(. /lib/ipq806x.sh && echo $(ipq806x_product_name))
        if [ "$model_name" == "RE-SS-02" ];then
            raw_hostname="JDBox_Athena"
        elif [ "$model_name" == "RE-CS-03" ];then
            raw_hostname="JDBox_HouYi"
        elif [ "$model_name" == "RE-OS-03U" ];then
            raw_hostname="JDBox_NeZha"
        elif [ "$model_name" == "RE-CS-04" ] ;then
            raw_hostname="Nezha"
        elif [ "$model_name" == "RE-CS-06" ] ;then
            raw_hostname="JDBox_ZhaoYun"
        elif [ "$model_name" == "RE-CS-08" ] ;then
            raw_hostname="JDBox_Taiyi_Plus"  
        elif [ "$model_name" == "RE-CS-07" ] ;then
            raw_hostname="JDBox_TaiYi"    
        elif [ "$model_name" == "jdc-ss01" ] ;then
            raw_hostname="JDBox_Arthur"    
        else
            raw_hostname="JDbox"
        fi
    elif [ -e "/lib/ramips.sh" ]; then
        model_name=$(. /lib/ramips.sh && echo $(ramips_product_name))
        raw_hostname="JDBox_LuBan"
    elif [ -e "/lib/functions.sh" ]; then
        model_name=$(. /lib/functions.sh;echo $(product_name))
        if [ "$model_name" == "RE-CP-03" ];then
            raw_hostname="JDBox_BaiLi"
        else
            raw_hostname="JDbox"
        fi
    fi
    model=$model_name
}

#获取原始mac地址
get_origin_mac_addr(){
    local origin_macaddr
    local sectionid
    local wan_ifname

    if [ "$model" = "RE-CP-03" ];then
        #baili
        section_id=`uci show network|grep "name='eth1'"|awk -F '.' '{print $2}'`
        origin_macaddr=`uci -q get network.$section_id.origin_macaddr`
    elif [ "$model" = "RE-CS-06" ]; then
        #zhaoyun
        origin_macaddr=`uci -q get network.wan_eth0_dev.origin_macaddr`
    elif [ "$model" = "RE-CS-08" ]; then
        #taiyi plus
        origin_macaddr=`uci -q get network.wan_1_dev.origin_macaddr`
    else
        origin_macaddr=`uci -q get network.wan.origin_macaddr`
    fi
    echo -n $origin_macaddr
}

#生成随机mac
generate_random_mac() {
    # 禁止的前缀列表（以冒号分隔的前两个十六进制数）
    BANNED_PREFIXES="dc:d8:7c 10:04:c1 2c:c4:4f"

    while true; do
        # 生成6个随机字节
        first_byte_hex=$(printf "%02x" $((0x$(openssl rand -hex 1) & 0xFE | 0x02)))
        remaining_bytes=`openssl rand -hex 5 | sed 's/\(..\)/\1:/g; s/:$//'|tr -d '\n'`
        mac_bytes="${first_byte_hex}:${remaining_bytes}"
        #echo "mac_bytes: $mac_bytes"
        if [ -z "$mac_bytes" ] || ! echo "$mac_bytes" | grep -qE '^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$'; then
            echo "mac_bytes $mac_bytes not valid"
            continue
        fi

        # 检查是否是组播地址（第1字节最低位是否为1）
        first_byte=$(echo "$mac_bytes" | awk -F ':' '{print $1}')
        if [ -z "$first_byte" ] || ! echo "$first_byte" | grep -qE '^[0-9a-fA-F]{2}$'; then
            echo "mac_bytes $mac_bytes first_byte not valid"
            continue
        fi
        if [ $((0x$first_byte & 0x01)) -eq 1 ]; then
            echo "mac_bytes $mac_bytes, is multicast"
            continue
        fi

        # 检查是否是广播地址（FF:FF:FF:FF:FF:FF）
        if [ "$mac_bytes" = "FF:FF:FF:FF:FF:FF" ]; then
            echo "mac_bytes $mac_bytes, is broadcast" 
            continue
        fi

        # 检查是否为禁止的前缀开头
        local prefix="${mac_bytes:0:8}"  # 提取前8个字符
        for banned in $BANNED_PREFIXES; do
            if [ "$prefix" == "$banned" ]; then
                echo "mac_bytes $mac_bytes, is equal to banned $banned" 
                continue 
            fi
        done

        random_mac=$mac_bytes
        break
    done
}

#生成随机hostname
generate_random_hostname() {
    local random_string

    # 生成随机字符串（12字节）
    # 允许字符：0-9, a-z, A-Z, -, _
    # 限制：-和_不能出现在开头和结尾

    # 定义允许的字符集（不包括-和_）
    charset="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    while true; do
        # 生成第一个字符（不能是-或_）
        rand_num=`head -c 1 /dev/urandom | hexdump -e '1/1 "%u"'`
        first_char="${charset:$((rand_num % ${#charset})):1}"

        # 生成中间10个字符（可以包含-和_）
        middle_chars=""
        for i in $(seq 1 10); do
            # 扩展字符集包含-和_
            extended_charset="${charset}-_"
            rand_num=`head -c 1 /dev/urandom | hexdump -e '1/1 "%u"'`
            middle_chars="${middle_chars}${extended_charset:$((rand_num % ${#extended_charset})):1}"
        done

        # 生成最后一个字符（不能是-或_）
        rand_num=`head -c 1 /dev/urandom | hexdump -e '1/1 "%u"'`
        last_char="${charset:$((rand_num % ${#charset})):1}"
        # 组合成最终字符串
        random_string="${first_char}${middle_chars}${last_char}"
        if echo "$random_string" |grep -iqE '[jJ][dD]|[jJ][dD][bB][oO][xX]|[jJ][dD][cC]|[jJ][dD][cC][lL][oO][uU][dD]|[jJ][dD][tT]'; then
            continue
        else
            random_hostname=$random_string
            break
        fi
    done
}

#设置mac地址克隆
set_mac_clone(){
    local clone_mac=$1
    local iptv_enable=`uci -q get jd_product.iptv_info.enable`
    local iptv_mode=`uci -q get jd_product.iptv_info.mode`
    local section_id

    if [ "$iptv_enable" = "1" ] && [ "$iptv_mode" = "0" ]; then
        uci set network.internet.macaddr=$clone_mac
    fi

    if [ "$model" = "RE-CP-03" ];then
        #baili
        ifname=`uci -q get network.wan.device`
        if ! echo "$ifname" | grep -q '^apcli'; then 
            section_id=`uci show network|grep "name='$ifname'"|awk -F '.' '{print $2}'`
        else
            section_id=`uci show network|grep "name='eth1'"|awk -F '.' '{print $2}'`
        fi
        uci set network.$section_id.macaddr=$clone_mac
    elif [ "$model" = "RE-CS-06" ]; then
        #zhaoyun
        uci set network.wan_eth0_dev.macaddr=$clone_mac
    elif [ "$model" = "RE-CS-08" ]; then
        #taiyi plus
        uci set network.wan_1_dev.macaddr=$clone_mac
    else
        uci set network.wan.macaddr=$clone_mac
    fi
    uci commit network
}

#设置hostname
set_hostname(){
    uci set system.@system[0].hostname=$1
    uci commit system
    echo "$1" > /proc/sys/kernel/hostname
}

#设置开启随机mac和hostname
set_random_mac_and_hostname_enable(){
    #local random_mac
    local random_hostname

    #设置随机mac和hostname开关
    uci set system.@system[0].random=1
    uci commit system

    #设置随机mac
    generate_random_mac
    if [ -n "$random_mac" ] && echo "$random_mac" | grep -qE '^([0-9a-f]{2}:){5}[0-9a-f]{2}$'; then
         logger -s "set random mac $random_mac"
         set_mac_clone $random_mac
    fi

    #设置随机hostname
    generate_random_hostname
    if [ -n "$random_hostname" ]; then
        logger -s "set random hostname $random_hostname"
        set_hostname $random_hostname
    fi
}

#设置关闭随机mac和hostname
set_random_mac_and_hostname_disable(){
    local type=$1
    random_enable=`uci -q get system.@system[0].random`
    if [ -n $random_enable ] && [ "$random_enable" -eq 1 ]; then
        #设置随机mac和hostname开关
        uci set system.@system[0].random=0
        uci commit system
    
        if [ $type -ne 1 ]; then
            #恢复默认mac地址
            originmac=$(get_origin_mac_addr)
            if [ -n "$originmac" ] && echo "$originmac" | grep -qE '^([0-9a-f]{2}:){5}[0-9a-f]{2}$'; then
                logger -s "recover random mac $originmac"
                set_mac_clone $originmac
            else
                logger -s "originmac $originmac not valid"
            fi
        
        fi

        if [ $type -ne 0 ]; then
            #恢复默认hostname
            if [ -z "$(uci -q get system.@system[0].origin_hostname)" ];then
                origin_hostname=$raw_hostname
                echo "recover random hostname from raw $origin_hostname"
            else
                origin_hostname=`uci -q get system.@system[0].origin_hostname`
                echo "recover random hostname from origin $origin_hostname"
            fi
            set_hostname $origin_hostname
        fi
    fi
}

############################################################
#命令行参数处理：
#参数1：reload：1/0
#参数2：使能/关闭:1/0  
#参数3：仅参数2为0时该参数有效，0 仅关闭mac地址克隆，1为仅关闭hostname， 2为全关闭
# 检查参数数量
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: \$0 <param1> [param2]"
    echo "  param1: 0 (disable) or 1 (enable)"
    echo "  param2: required when param1=0, 0 (only host) or 1 (only hostname) other all"
    exit 1
fi

get_product_name
echo "model $model, raw_hostname $raw_hostname"
enable=$1
if [ "$enable" -eq 0 ]; then
    disable_type=2
    # 检查是否需要第三个参数
    if [ $# -eq 2 ]; then
        # 第三个参数处理
        disable_type=$2
        if [ "$disable_type" -ne 0 ] && [ "$disable_type" -ne 1 ]; then
            disable_type=2
        fi
    fi
    set_random_mac_and_hostname_disable $disable_type

elif [ "$enable" -eq 1 ]; then
    set_random_mac_and_hostname_enable
elif [ "$enable" -eq 2 ]; then
    ran=`uci -q get system.@system[0].random`
    if [ -n $ran ] && [ "$ran" -eq 1 ]; then
        set_random_mac_and_hostname_enable
    fi
else
    echo "Error: enable must be 0 or 1"
    exit 1
fi


