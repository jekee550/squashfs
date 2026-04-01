#!/bin/sh
#1.42.1 Controller configuration - with repacd (auto)
#NOTE: The channels and bandwidths here are fixed only for illustrative purposes. They may
#be left unset to allow for automatic selection if desired.

#-------------------------------------------
# Steps on Controller
# Based on BSS Instantiation Scheme A
#-------------------------------------------
wifimeshconfig map
uci set wireless.wifi0.repacd_create_ctrl_fbss=1
uci set wireless.wifi0.repacd_create_ctrl_bbss=1
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




