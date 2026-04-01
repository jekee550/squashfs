#!/bin/sh

wan_interface="eth4"
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

define_interface() {
	if [ "$dev_type" = "RE-CP-03" ];then
		#baili
		wan_interface="$(uci get network.wan.device 2>/dev/null)"
	else
		wan_interface="$(uci get network.wan.ifname 2>/dev/null)"
		if [ "$dev_type" = "RE-CS-06" ]; then
			[ "$wan_interface" == "br-internet" ] && {
				wan_interface="eth0"
			}
		fi
	fi

	if [ -z "$wan_interface" ];then
		wan_interface='br-lan'
	elif [ "$(uci get network.wan.proto 2>/dev/null)" == "pppoe" ];then
		wan_interface="pppoe-wan"
	fi
}

create_ipt_rule() {
	local ipt=$1

	#delete_chain_from_table "mangle" "qos_dev_egress";
	$ipt -w -t mangle -F qos_dev_egress 2>/dev/null
	$ipt -w -t mangle -D FORWARD -j qos_dev_egress 2>/dev/null
	$ipt -w -t mangle -X qos_dev_egress 2>/dev/null

	#delete_chain_from_table "mangle" "qos_dev_ingress";
	$ipt -w -t mangle -F qos_dev_ingress 2>/dev/null
	$ipt -w -t mangle -D FORWARD -j qos_dev_ingress 2>/dev/null
	$ipt -w -t mangle -X qos_dev_ingress 2>/dev/null

	#delete_chain_from_table "mangle" "LOCAL_RQ"
	$ipt -w -t mangle -F LOCAL_RQ 2>/dev/null
	$ipt -w -t mangle -D OUTPUT -o $wan_interface -j LOCAL_RQ 2>/dev/null
	$ipt -w -t mangle -X LOCAL_RQ 2>/dev/null

	for line in $($ipt -w -t mangle -nvL qos_dev_egress --line-number 2>/dev/null | grep -w MARK | awk '{print $1}');do
		$ipt -w -t mangle -D qos_dev_egress $line
	done

	for line in $($ipt -w -t mangle -nvL qos_dev_ingress --line-number 2>/dev/null | grep -w MARK | awk '{print $1}');do
		$ipt -w -t mangle -D qos_dev_ingress $line
	done

	$ipt -w -t mangle -N qos_dev_ingress
	$ipt -w -t mangle -N qos_dev_egress

	$ipt -w -t mangle -A FORWARD -j qos_dev_ingress
	$ipt -w -t mangle -A FORWARD -j qos_dev_egress

	#delete_chain_from_table "mangle" "LOCAL_RQ"
	logger "smartqos:create LOCAL_RQ!!!!!"
	$ipt -w -t mangle -N LOCAL_RQ
	[ $? != 0 ] && {
		logger "smartqos:create LOCAL_RQ again!!!!!"
		$ipt -w -t mangle -N LOCAL_RQ
	}

	if [ "$ipt" = "ip6tables" ]; then
		if [ "$(uci get ipv6.config.enabled)" = "1" -a $(uci get ipv6.config.mode) = "relay" ]; then
			$ipt -w -t mangle -D OUTPUT -o br-lan -j LOCAL_RQ 2>/dev/null
			$ipt -w -t mangle -A OUTPUT -o br-lan -j LOCAL_RQ
		else
			$ipt -w -t mangle -D OUTPUT -o $wan_interface -j LOCAL_RQ 2>/dev/null
			$ipt -w -t mangle -A OUTPUT -o $wan_interface -j LOCAL_RQ
		fi
	else
		$ipt -w -t mangle -D OUTPUT -o $wan_interface -j LOCAL_RQ 2>/dev/null
		$ipt -w -t mangle -A OUTPUT -o $wan_interface -j LOCAL_RQ
	fi

	#plugin chain
	#delete_chain_from_table "mangle" "qos_egress"
	$ipt -w -t mangle -F qos_egress 2>/dev/null
	$ipt -w -t mangle -D POSTROUTING -o $wan_interface -j qos_egress 2>/dev/null
	$ipt -w -t mangle -X qos_egress 2>/dev/null

	for line in $($ipt -w -t mangle -nvL qos_egress --line-number 2>/dev/null | grep -w MARK | awk '{print $1}');do
		$ipt -w -t mangle -D qos_egress $line
	done

	$ipt -w -t mangle -N qos_egress 2>/dev/null
	if [ "$ipt" = "ip6tables" ]; then
		if [ "$(uci get ipv6.config.enabled)" = "1" -a $(uci get ipv6.config.mode) = "relay" ]; then
			$ipt -w -t mangle -D POSTROUTING -o br-lan -j qos_egress 2>/dev/null
			$ipt -w -t mangle -I POSTROUTING -o br-lan -j qos_egress
		else
			$ipt -w -t mangle -D POSTROUTING -o $wan_interface -j qos_egress 2>/dev/null
			$ipt -w -t mangle -I POSTROUTING -o $wan_interface -j qos_egress
		fi
	else
		$ipt -w -t mangle -D POSTROUTING -o $wan_interface -j qos_egress 2>/dev/null
		$ipt -w -t mangle -I POSTROUTING -o $wan_interface -j qos_egress
	fi

	if [ "$(uci get smartqos.qos.enable 2>/dev/null)" != "1" ];then
		return
	fi

	if [ "$dev_type" = "RE-CP-03" -o "$dev_type" = "RE-CP-02" -o "$dev_type" = "RE-CS-06" ];then
		$ipt -w -t mangle -A qos_egress -p udp --dport 53 -j CLASSIFY --set-class 1:400
		$ipt -w -t mangle -A qos_egress -p icmp -j CLASSIFY --set-class 1:400
	else
		$ipt -w -t mangle -A qos_egress -p udp --dport 53 -j CLASSIFY --set-class 400:0
		$ipt -w -t mangle -A qos_egress -p icmp -j CLASSIFY --set-class 400:0
	fi

	#MODE_DOWN = 0,				//积分优先：除了DNS不做任何优先
	#MODE_DEFAULT,				//智能加速：开启网页优先和游戏优先
	#MODE_WEB,				//开启网页优先和小包优先
	#MODE_UNLIMITED,			//极限积分:除了DNS不做任何优先,放开内存限制

	if [ $smartqos_mod -eq 1 -o $smartqos_mod -eq 2 ]; then
		$ipt -t mangle -A LOCAL_RQ -m connmark --mark 801 -j RETURN
		$ipt -t mangle -A LOCAL_RQ -p tcp --dport 2002 -j CONNMARK --set-mark 801

		if [ "$dev_type" = "RE-CP-03" -o "$dev_type" = "RE-CP-02" -o "$dev_type" = "RE-CS-06" ];then
			$ipt -t mangle -A qos_egress -m connmark --mark 801 -j CLASSIFY --set-class 1:300
		else
			$ipt -t mangle -A qos_egress -m connmark --mark 801 -j CLASSIFY --set-class 300:0
		fi

		$ipt -t mangle -A qos_egress -m connmark --mark 801 -j RETURN
	fi
}

do_iptables() {
	#修复文件属性错误
	if [ -z "$(ls -lh /etc/config/smartqos | grep ^-)" ];then
		rm -f /etc/config/smartqos
		cp /rom/etc/config/smartqos /etc/config/
	fi

	#smartqos文件异常的时候会走到这里
	if [ -z "$(uci get smartqos.qos.enable 2>/dev/null)" ];then
		logger "smartqos:restore config file"
		mode_old=`head /etc/config/smartqos | grep "mode " | awk -F "'" '{print $2}'`
		cp -f /rom/etc/config/smartqos /etc/config/
		[ -n "$mode_old" ] && uci set smartqos.qos.mode=$mode_old;uci commit smartqos
		#需要用户重新配置限速
		sed -i "s/option qos_enable '1'/option qos_enable '0'/g" /etc/config/jd_stainfo
	fi

	create_ipt_rule iptables

	create_ipt_rule ip6tables
}

define_interface
do_iptables

