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

uci set system.@system[0].re_init='1'
uci commit system
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
#for ya dian na
#uci delete wireless.wifi2
#uci delete wireless.ath2
#uci delete wireless.ath21
#uci delete wireless.ath22

uci set wireless.wifi0.repacd_map_bsta_preference=1 #5G
uci set wireless.wifi1.repacd_map_bsta_preference=0
uci set wireless.qcawifi=qcawifi
uci set wireless.qcawifi.samessid_disable=1
uci commit wireless
uci set wsplcd.config.DebugLevel='DUMP'
uci set wsplcd.config.WriteDebugLogToFile='APPEND'
uci set wsplcd.config.MapMaxBss=2

uci set wsplcd.config.ConfigApplyTimeout=1

uci commit wsplcd

#uci set ezmesh.MultiAP.EnableChannelSelection=1
uci commit ezmesh

uci set repacd.repacd.Ezmesh='1'
uci set repacd.repacd.Enable=1
uci set repacd.repacd.ConfigREMode='son'
uci set repacd.MAPConfig.FirstConfigRequired=1
uci set repacd.MAPConfig.Enable=1
uci set repacd.MAPWiFiLink.RSSINumMeasurements='0'
uci set repacd.MAPWiFiLink.MinAssocCheckPostWPS='1'
uci set repacd.MAPConfig.MapCountry='CN'
uci commit repacd

/etc/init.d/repacd start
#--------------------------------------------------
# WPS Event
#--------------------------------------------------
echo 'env -i ACTION="pressed" BUTTON="wps" /sbin/hotplug-call button;sleep 1;env -i ACTION="released" BUTTON="wps" /sbin/hotplug-call button' > /dev/console
env -i ACTION="pressed" BUTTON="wps" /sbin/hotplug-call button;sleep 1;env -i ACTION="released" BUTTON="wps" /sbin/hotplug-call button
/etc/init.d/hyfi-bridging stop &



