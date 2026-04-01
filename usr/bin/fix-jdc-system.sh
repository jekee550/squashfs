#!/bin/sh

logger $0:restore system config file!!!
hostname=
product_name=
if [ -e "/lib/ipq806x.sh" ]; then
    model_name=$(. /lib/ipq806x.sh && echo $(ipq806x_product_name))
    if [ "$model_name" == "RE-SS-02" ];then
        hostname="JDBox_Athena"
        product_name="Athena"
    elif [ "$model_name" == "RE-CS-03" ];then
        hostname="JDBox_HouYi"
        product_name="Houyi"
    elif [ "$model_name" == "RE-OS-03U" ];then
        hostname="JDBox_NeZha"
        product_name="Nezha"
    elif [ "$model_name" == "RE-CS-04" ] ;then
        hostname="Nezha"
        product_name="Nezha"
    elif [ "$model_name" == "RE-CS-06" ] ;then
        hostname="JDBox_ZhaoYun"
        product_name="ZhaoYun"
    elif [ "$model_name" == "RE-CS-08" ] ;then
        hostname="JDBox_Taiyi_Plus"
        product_name="TaiYi_Plus"
    elif [ "$model_name" == "RE-CS-07" ] ;then
        hostname="JDBox_TaiYi" 
        product_name="TaiYi" 
    elif [ "$model_name" == "jdc-ss01" ] ;then
        hostname="JDBox_Arthur"
        product_name="Arthur"
    else
        hostname="JDBox"
        product_name="JDBox"
    fi
elif [ -e "/lib/ramips.sh" ]; then
    hostname="JDBox_LuBan"
elif [ -e "/lib/functions.sh" ]; then
    model_name=$(. /lib/functions.sh;echo $(product_name))
    if [ "$model_name" == "RE-CP-03" ];then
        hostname="JDBox_BaiLi"
    else
        hostname="JDBox"
    fi
fi

sys_hostname=`cat /proc/sys/kernel/hostname |tr -d '\n'`
if [ -n "$sys_hostname" ] && [ "$sys_hostname" != "(none)" ]; then
	hostname=$sys_hostname
fi

#recover system config file 
[ -e /lib/ipq806x.sh ] && dev_type=$(. /lib/ipq806x.sh && echo $(ipq806x_product_name))
if [ "$dev_type" = "RE-CS-06" ] || [ "$dev_type" = "RE-CS-08" ]; then
	rm /etc/config/system
	/bin/config_generate
	#fix freq_mode
	if [ -e "/etc/jdwifi/split" ]; then
		uci set system.@system[0].freq_mode=1
	fi
else
	cp /rom/etc/config/system /etc/config
fi

#fix led switch
timer_configured=0
led_b=`cat /sys/class/leds/led_b1/brightness|tr -d '\n'`
led_r=`cat /sys/class/leds/led_r1/brightness|tr -d '\n'`
led_g=`cat /sys/class/leds/led_g1/brightness|tr -d '\n'`
led_paths="/sys/class/leds/led_r1/trigger /sys/class/leds/led_b1/trigger /sys/class/leds/led_g1/trigger"
for led_path in $led_paths; do
    if [ -f "$led_path" ]; then
        if grep -q "\[timer\]" "$led_path"; then
                timer_configured=1
                #echo "Timer configured for $led_path"
                break
        fi
    fi
done

if [ $led_b -eq 0 ] && [ $led_r -eq 0 ] && [ $led_g -eq 0 ] && [ $timer_configured -eq 0 ];then
	uci set system.led_switch.enable=0
fi

#fix hostname
uci set system.@system[0].hostname=$hostname
#fix product_name
uci set system.@system[0].product_name=$product_name

sh /rom/etc/uci-defaults/leds
sh /rom/etc/uci-defaults/system_check
if [ "$(uci -q get network.lan.proto)" = "static" ];then
	[ -n "$(pgrep -x ezmesh)" -o "$(uci -q get jdc_ezmesh.ezmesh.role)" = "controller" ] && uci set system.@system[0].cap_init='1'
elif [ "$(uci -q get network.lan.proto)" = "dhcp" ];then
	if [ -n "$(pgrep -x ezmesh)" ];then
		[ "$(uci -q get jdc_ezmesh.ezmesh.role)" = "controller" ] && uci set system.@system[0].cap_init='1' && uci set system.@system[0].apmode_init='1'
		[ "$(uci -q get jdc_ezmesh.ezmesh.role)" = "agent" ] && uci set system.@system[0].re_init='1'
	else
		uci set system.@system[0].apmode_init='1'
	fi
fi

if [ "$dev_type" = "RE-SS-02" ];then
	uci set system.screen_switch=srceen
	uci set system.screen_switch.time='1'
	uci set system.screen_switch.uprate='1'
	uci set system.screen_switch.downrate='0'
	uci set system.screen_switch.stanum='0'
	uci set system.screen_switch.weather='0'
	uci set system.screen_switch.points='1'
	uci set system.screen_switch.enable='1'
	uci set system.screen_switch.switch='0'
	uci commit system
fi

if ! ubus call session login '{"username":"root","password":"admin"}' >/dev/null 2>&1;then
	uci set system.@system[0].intialized='1'
fi
uci commit system
/etc/init.d/system restart
/sbin/jd_get_publicip.sh&
/opt/etc/nattype.sh&