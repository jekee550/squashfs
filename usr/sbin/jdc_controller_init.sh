#!/bin/sh
#1.42.1 Controller configuration - with repacd (auto)
#NOTE: The channels and bandwidths here are fixed only for illustrative purposes. They may
#be left unset to allow for automatic selection if desired.

#-------------------------------------------
# Steps on Controller
# Based on BSS Instantiation Scheme A
#-------------------------------------------
uci set system.led_power.default='0'
uci set system.led_network.default='0'
uci set system.led_plugin.default='0'
uci set system.led_switch.enable='0'
uci set system.@system[0].cap_init='1'
uci commit system
/etc/init.d/led start
echo timer > /sys/class/leds/led_b1/trigger
echo 200 > /sys/class/leds/led_b1/delay_off
echo 200 > /sys/class/leds/led_b1/delay_on


wifimeshconfig map
uci set wireless.wifi0.repacd_create_ctrl_fbss=1
uci set wireless.wifi0.repacd_create_ctrl_bbss=0
uci set wireless.wifi1.repacd_create_ctrl_fbss=1
uci set wireless.wifi1.repacd_create_ctrl_bbss=1
uci set wireless.qcawifi=qcawifi
uci set wireless.qcawifi.samessid_disable=1
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
uci commit wireless
uci set repacd.repacd.Ezmesh='1'
uci set repacd.repacd.Enable='1'
uci set repacd.repacd.ConfigREMode='son'
uci set repacd.MAPConfig.Enable=1
uci set repacd.MAPConfig.FirstConfigRequired=1
uci set repacd.MAPConfig.BSSInstantiationTemplate='scheme-a.conf'
uci set repacd.MAPConfig.FronthaulSSID='aaaaaaaaaa'
uci set repacd.MAPConfig.FronthaulKey='12345678'
uci set repacd.MAPConfig.BackhaulSSID='EzMeshBackhaul'
uci set repacd.MAPConfig.BackhaulKey='EzMeshBackhaulKey'
uci set repacd.MAPConfig.MapCountry='CN'


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
uci set ezlbd.Estimator_Adv.ActDetectMinInterval='10'
uci set ezlbd.Estimator_Adv.ActDetectMinPktPerSec='5'
uci set ezlbd.APSteer.LowRSSIAPSteerThreshold_SIG='35'
uci set ezlbd.APSteer.APSteerMaxRetryCount='20'
uci set ezlbd.StaDB.MarkAdvClientAsDualBand=1
uci set ezlbd.SteerExec_Adv.StartInBTMActiveState=1
uci set ezlbd.config.InactDetectionFromTx='1'
uci commit ezlbd
uci set ezmesh.MultiAP.EnableChannelSelection=1
uci set ezmesh.MultiAP.BkScanIntervalMin=0
uci set ezmesh.MultiAP.ChannelSelectionDelaySec=0
uci set ezmesh.MultiAP.ChannelSelectionOnGlobalPref=0
uci set ezmesh.MultiAP.EnableTopologyOpt=1
uci commit ezmesh
/etc/init.d/repacd start
#--------------------------------------------------
# WPS Event
#--------------------------------------------------
echo 'env -i ACTION="pressed" BUTTON="wps" /sbin/hotplug-call button;sleep 1;env -i ACTION="released" BUTTON="wps" /sbin/hotplug-call button' > /dev/console
env -i ACTION="pressed" BUTTON="wps" /sbin/hotplug-call button;sleep 1;env -i ACTION="released" BUTTON="wps" /sbin/hotplug-call button




