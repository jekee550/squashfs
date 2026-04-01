#!/bin/sh

#脚本调用关系
#/etc/hotplug.d/net/32_jdc_wpacli  wpacli -a  for me
IFNAME=$1
CMD=$2

case "$CMD" in
    CONNECTED)
        if echo "${IFNAME}" | grep -q "^ath[0-2]5$"; then
            echo "${IFNAME} event :IFNAME=$IFNAME CMD=$CMD  " > /dev/console
	    kill -USR1 $(pidof udhcpc)
	    logger -t "${IFNAME} event" -p user.info "IFNAME=$IFNAME CMD=$CMD and kill -USR1 tp udhcpc"
            #hyctl show
            #br_name br_mode fw_mode tcp_sp  interfaces      type    grp_num bcast   port_type
            #br-lan  GRPREL  SINGLE  disable ath05           norelay 0       disable  Wi-Fi 5GHz 
            #                                ath1            relay   1       enable  Wi-Fi 2GHz
            #                                ath06           relay   1       enable  Wi-Fi 5GHz
            #                                ath0            relay   1       enable  Wi-Fi 5GHz
            #遇到了一个明确且无法不复现的问题，此时虽然可以连接到主路由的bk-ap口上,但是dhcp不通
            #无法获取到IP地址
            #当子路由的sta-vap:ath[0-2]5的bcast为disable。
            #正常情况下我们使用hyctl setifbcast br-lan ${IFNAME} disable,也会被自动修改会enable.
            #ezmesh进程会调用libhyficommon 库函数,netlink通知到内核模块hyfi桥 主动修改接口的bcast的参数
            #故再次使用脚本借助与wpa_supplicant的连接事件检查修复此概率问题
            sleep 2 && [ -z "$(hyctl show | grep ${IFNAME} | grep "enable")" ] && hyctl setifbcast br-lan ${IFNAME} enable &
         fi
      ;;
    DISCONNECTED)
        if echo "${IFNAME}" | grep -q "^ath[0-2]5$"; then
            echo "${IFNAME} event:IFNAME=$IFNAME CMD=$CMD" > /dev/console
	    logger -t "${IFNAME} event" -p user.info "IFNAME=$IFNAME CMD=$CMD"
        fi
      ;;
esac
