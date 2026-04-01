#!/bin/sh




function set_in_progress() {
  echo default-on > /sys/class/leds/led_g1/trigger
  echo default-on > /sys/class/leds/led_r1/trigger
  echo 0 > /sys/class/leds/led_g1/brightness
  echo 0 > /sys/class/leds/led_r1/brightness

  echo timer > /sys/class/leds/led_b1/trigger
  echo 500 > /sys/class/leds/led_b1/delay_on
  echo 500 > /sys/class/leds/led_b1/delay_off

}

function set_wps_start() {
  echo default-on > /sys/class/leds/led_g1/trigger
  echo default-on > /sys/class/leds/led_r1/trigger
  echo 0 > /sys/class/leds/led_g1/brightness
  echo 0 > /sys/class/leds/led_r1/brightness

  echo timer > /sys/class/leds/led_b1/trigger
  echo 250 > /sys/class/leds/led_b1/delay_on
  echo 250 > /sys/class/leds/led_b1/delay_off
}

function set_wps_config() {
  echo default-on > /sys/class/leds/led_g1/trigger
  echo default-on > /sys/class/leds/led_r1/trigger
  echo 0 > /sys/class/leds/led_g1/brightness
  echo 0 > /sys/class/leds/led_r1/brightness

  echo timer > /sys/class/leds/led_b1/trigger
  echo 100 > /sys/class/leds/led_b1/delay_on
  echo 100 > /sys/class/leds/led_b1/delay_off
}


function set_wps_fail() {
  echo default-on > /sys/class/leds/led_g1/trigger
  echo default-on > /sys/class/leds/led_b1/trigger
  echo 0 > /sys/class/leds/led_b1/brightness
  echo 0 > /sys/class/leds/led_g1/brightness

  echo timer > /sys/class/leds/led_r1/trigger
  echo 200 > /sys/class/leds/led_r1/delay_on
  echo 200 > /sys/class/leds/led_r1/delay_off
  
  sleep 3 
  if [ "$(uci -q get jdc_ezmesh.ezmesh.user_turns_on_led)" = "0" ];then
      uci set system.led_switch.enable='0'
  else
      uci set system.led_switch.enable='1'
  fi
  if [ "$(uci -q get jd_product.network.connected)" == "1" ];then
      uci set system.led_power.default='0'
      uci set system.led_network.default='1'
  else
      uci set system.led_power.default='1'
      uci set system.led_network.default='0'
  fi
  uci set system.led_plugin.default='0'
  uci commit system
  ##wps timeout超时由系统接管灯的状态
  /etc/init.d/led restart &
}

#停用上网管家功能
set_net_manager_disable(){
        uci -q set role_group.global.switch_enable=0
        uci commit role_group
        rule_apply role_group reload
        rule_apply app_filter reload
        rule_apply mac_filter reload
        /usr/sbin/jdc_harm_rule.sh delIptables 2>/dev/null;/usr/sbin/jdc_harm_rule.sh delIpset 2>/dev/null
}

function set_wps_success() {
  echo default-on > /sys/class/leds/led_r1/trigger
  echo default-on > /sys/class/leds/led_g1/trigger
  echo default-on > /sys/class/leds/led_b1/trigger
  echo 0 > /sys/class/leds/led_r1/brightness
  echo 0 > /sys/class/leds/led_g1/brightness
  echo 1 > /sys/class/leds/led_b1/brightness
  ##wps 组网成功系统接管灯的状态
  sleep 10
  if [ "$(uci -q get jdc_ezmesh.ezmesh.user_turns_on_led)" = "0" ];then
      uci set system.led_switch.enable='0'
  else
      uci set system.led_switch.enable='1'
  fi
  uci set system.led_plugin.default='0'
  if [ "$(uci -q get jd_product.network.connected)" == "1" ];then
      uci set system.led_power.default='0'
      uci set system.led_network.default='1'
  else
      uci set system.led_power.default='1'
      uci set system.led_network.default='0'
  fi
  uci commit system
  /etc/init.d/led restart &
  
  if [ "$(uci -q get system.@system[0].re_init)" == "1" ];then
	#停用上网管家功能
	set_net_manager_disable  	
  fi
}


function set_signal_good() {
  echo default-on > /sys/class/leds/led_r1/trigger
  echo default-on > /sys/class/leds/led_g1/trigger
  echo default-on > /sys/class/leds/led_b1/trigger
  echo 0 > /sys/class/leds/led_r1/brightness
  echo 0 > /sys/class/leds/led_g1/brightness
  echo 1 > /sys/class/leds/led_b1/brightness

  ##信号强度恢复后由系统接管灯的状态
  sleep 5 && /etc/init.d/led restart &

}


function set_signal_fair() {
  echo default-on > /sys/class/leds/led_g1/trigger
  echo default-on > /sys/class/leds/led_r1/trigger
  echo 0 > /sys/class/leds/led_g1/brightness
  echo 0 > /sys/class/leds/led_b1/brightness

  echo timer > /sys/class/leds/led_r1/trigger
  echo 500 > /sys/class/leds/led_r1/delay_on
  echo 100 > /sys/class/leds/led_r1/delay_off

}


function set_signal_poor() {
  echo default-on > /sys/class/leds/led_g1/trigger
  echo default-on > /sys/class/leds/led_r1/trigger
  echo 0 > /sys/class/leds/led_g1/brightness
  echo 0 > /sys/class/leds/led_b1/brightness

  echo timer > /sys/class/leds/led_r1/trigger
  echo 500 > /sys/class/leds/led_r1/delay_on
  echo 100 > /sys/class/leds/led_r1/delay_off
}

cur_state=`cat /tmp/wifimon_state`
if [ "$1" == "$cur_state" -o -z "$1" ];then
	exit 1;
fi

#echo $1 > /tmp/wifimon_state
logger -p user.info "jdc_ezmesh_ledctl  : This State ["${1}"]"

if [ "$1" == "wps_fail" ];then
        set_wps_fail
elif [ "$1" == "in_progress" ];then
        set_in_progress
elif [ "$1" == "signal_good" ];then
        set_signal_good
elif [ "$1" == "signal_fair" ];then
        set_signal_fair
elif [ "$1" == "signal_poor" ];then
        set_signal_poor
elif [ "$1" == "wps_start" ];then
	      set_wps_start
elif [ "$1" == "wps_success" ];then
	      set_wps_success
elif [ "$1" == "wps_config" ];then
	set_wps_config
else
	logger -p user.warn "jdc_ezmesh_ledctl : No Support This State ["${1}"]"
	exit 1;
fi

echo $1 > /tmp/wifimon_state
