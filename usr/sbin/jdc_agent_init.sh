#!/bin/sh
#1.42.3 Agent configuration - with repacd
#NOTE: When channel selection is enabled, the channels and bandwidths need not be set on
#the agent (and if they are, they will be overwritten by the Channel Selection Request
#message from the controller).
#NOTE: This is a sample configuration that uses repacd.


#--------------------------------------------------------
# Steps on Agent - Wi-Fi onboarding - with repacd
#--------------------------------------------------------
wifimeshconfig map

uci set system.led_power.default='0'
uci set system.led_network.default='0'
uci set system.led_plugin.default='0'
uci set system.led_switch.enable='0'
uci set system.@system[0].re_init='1'
uci commit system
/etc/init.d/led start
echo timer > /sys/class/leds/led_b1/trigger
echo 200 > /sys/class/leds/led_b1/delay_off
echo 200 > /sys/class/leds/led_b1/delay_on

uci set network.lan.proto=dhcp
uci delete network.wan;
uci commit network
uci set dhcp.lan.ignore=1
uci commit dhcp
#/etc/init.d/network restart
/etc/init.d/network light_reload
/etc/init.d/dnsmasq restart

#uci set wireless.@wifi-iface[5].wsplcd_unmanaged=1
#uci set wireless.@wifi-iface[5].repacd_security_unmanaged=1

uci delete wireless.ath01
uci delete wireless.ath02
uci delete wireless.ath11
uci delete wireless.ath12
uci delete wireless.wifi2
uci delete wireless.ath2
uci delete wireless.ath21
uci delete wireless.ath22

uci set wireless.wifi0.repacd_map_bsta_preference=0
uci set wireless.wifi1.repacd_map_bsta_preference=2
uci set wireless.qcawifi=qcawifi
uci set wireless.qcawifi.samessid_disable=1
uci commit wireless
uci set wsplcd.config.DebugLevel='DUMP'
uci set wsplcd.config.WriteDebugLogToFile='APPEND'
uci set wsplcd.config.MapMaxBss=2
uci set wsplcd.config.VapSpecificRestart=1
uci set wsplcd.config.ConfigApplyTimeout=1
uci set wsplcd.config.MapFastOnboarding=1
uci commit wsplcd

uci set ezmesh.MultiAP.EnableChannelSelection=1
uci commit ezmesh

uci set repacd.repacd.Ezmesh='1'
uci set repacd.repacd.Enable=1
uci set repacd.repacd.ConfigREMode='son'
uci set repacd.MAPConfig.FirstConfigRequired=1
uci set repacd.MAPConfig.Enable=1
uci set repacd.MAPWiFiLink.RSSINumMeasurements='1'
uci set repacd.MAPWiFiLink.MinAssocCheckPostWPS='1'
uci set repacd.MAPConfig.MapCountry='CN'
uci set repacd.MAPConfig.SkipStaRestart='1'

#set LEDS
uci set repacd.NotAssociated.Name_1='led_network'
uci set repacd.NotAssociated.Trigger_1='timer'
uci set repacd.NotAssociated.Brightness_1='1'
uci set repacd.NotAssociated.DelayOn_1='500'
uci set repacd.NotAssociated.DelayOff_1='500'

uci set repacd.AutoConfigInProgress.Name_1='led_network'
uci set repacd.AutoConfigInProgress.Trigger_1='timer'
uci set repacd.AutoConfigInProgress.Brightness_1='1'
uci set repacd.AutoConfigInProgress.DelayOn_1='250'
uci set repacd.AutoConfigInProgress.DelayOff_1='250'

uci set repacd.Measuring.Name_1='led_network'
uci set repacd.Measuring.Trigger_1='timer'
uci set repacd.Measuring.Brightness_1='1'
uci set repacd.Measuring.DelayOn_1='500'
uci set repacd.Measuring.DelayOff_1='500'

uci set repacd.WPSTimeout.Name_1='led_power'
uci set repacd.WPSTimeout.Trigger_1='timer'
uci set repacd.WPSTimeout.Brightness_1='1'
uci set repacd.WPSTimeout.DelayOn_1='2000'
uci set repacd.WPSTimeout.DelayOff_1='1000'

uci set repacd.AssocTimeout.Name_1='led_power'
uci set repacd.AssocTimeout.Trigger_1='timer'
uci set repacd.AssocTimeout.Brightness_1='1'
uci set repacd.AssocTimeout.DelayOn_1='5000'
uci set repacd.AssocTimeout.DelayOff_1='1000'

uci set repacd.InCAPMode.Name_1='led_plugin'
uci set repacd.InCAPMode.Trigger_1='none'
uci set repacd.InCAPMode.Brightness_1='1'

uci set repacd.RE_BackhaulGood.Name_1='led_network'
uci set repacd.RE_BackhaulGood.Trigger_1='none'
uci set repacd.RE_BackhaulGood.Brightness_1='1'

uci set repacd.RE_BackhaulFair.Name_1='led_network'
uci set repacd.RE_BackhaulFair.Trigger_1='none'
uci set repacd.RE_BackhaulFair.Brightness_1='1'

uci set repacd.RE_BackhaulPoor.Name_1='led_network'
uci set repacd.RE_BackhaulPoor.Trigger_1='none'
uci set repacd.RE_BackhaulPoor.Brightness_1='0'

uci set repacd.RE_SwitchingBSTA.Name_1='led_network'
uci set repacd.RE_SwitchingBSTA.Trigger_1='timer'
uci set repacd.RE_SwitchingBSTA.Brightness_1='1'
uci set repacd.RE_SwitchingBSTA.DelayOn_1='100'
uci set repacd.RE_SwitchingBSTA.DelayOff_1='100'

uci commit repacd

/etc/init.d/repacd start
#--------------------------------------------------
# WPS Event
#--------------------------------------------------
echo 'env -i ACTION="pressed" BUTTON="wps" /sbin/hotplug-call button;sleep 1;env -i ACTION="released" BUTTON="wps" /sbin/hotplug-call button' > /dev/console
env -i ACTION="pressed" BUTTON="wps" /sbin/hotplug-call button;sleep 1;env -i ACTION="released" BUTTON="wps" /sbin/hotplug-call button



