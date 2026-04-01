#!/bin/ash

MESH_BACK_DIR="/etc/config/ezmesh_backup"

if [ -e /lib/ipq806x.sh ];then
	g_product_model=$(. /lib/ipq806x.sh && echo $(ipq806x_product_name))
elif [ -e /lib/ramips.sh ];then
	g_product_model=$(. /lib/ramips.sh && echo $(ramips_product_name))
else
	g_product_model=$(. /lib/functions.sh && echo $(product_name))
fi

qca_controller_backups_config()
{
    [ ! -d "$MESH_BACK_DIR" ] && mkdir  $MESH_BACK_DIR
    cp /etc/config/wireless $MESH_BACK_DIR
    cp /etc/config/repacd   $MESH_BACK_DIR
    cp /etc/config/wsplcd   $MESH_BACK_DIR
    cp /etc/config/ezlbd    $MESH_BACK_DIR
    cp /etc/config/ezmesh   $MESH_BACK_DIR

}

configure_wifi() {
    local interface=$1
    local ssid=$2
    local encryption=$3
    local key=$4

    # Check if interface already exists
    if ! uci -c $MESH_BACK_DIR/ -q get wireless.$interface; then
        uci -c $MESH_BACK_DIR/ add wireless wifi-iface
        uci -c $MESH_BACK_DIR/ rename wireless.@wifi-iface[-1]=$interface
	uci -c $MESH_BACK_DIR/ set wireless.$interface.device=wifi${interface:3:1}
	uci -c $MESH_BACK_DIR/ set wireless.$interface.network=wan
	uci -c $MESH_BACK_DIR/ set wireless.$interface.mode=sta
	uci -c $MESH_BACK_DIR/ set wireless.$interface.ssid=$ssid
	uci -c $MESH_BACK_DIR/ set wireless.$interface.extap=1
	uci -c $MESH_BACK_DIR/ set wireless.$interface.athnewind=1
	uci -c $MESH_BACK_DIR/ set wireless.$interface.encryption=$encryption
	uci -c $MESH_BACK_DIR/ set wireless.$interface.key=$key
	uci -c $MESH_BACK_DIR/ set wireless.$interface.ifname=$interface
	uci -c $MESH_BACK_DIR/ set wireless.$interface.disabled=1
    fi
}


qca_quilt_controller(){
    uci set system.@system[0].cap_init='0'
    uci commit system
    ath0_ssid=`uci -q get wireless.ath0.ssid`
    [ -n "$ath0_ssid" ] && uci -c $MESH_BACK_DIR/ set wireless.ath0.ssid="$ath0_ssid"
    ath0_key=`uci -q get wireless.ath0.key`
    [ -n "$ath0_key" ] && uci -c $MESH_BACK_DIR/ set wireless.ath0.key="$ath0_key"

    ath1_ssid=`uci -q get wireless.ath1.ssid`
    [ -n "$ath1_ssid" ] && uci -c $MESH_BACK_DIR/ set wireless.ath1.ssid="$ath1_ssid"
    ath1_key=`uci -q get wireless.ath1.key`
    [ -n "$ath1_key" ] && uci -c $MESH_BACK_DIR/ set wireless.ath1.key="$ath1_key"

    ath2_ssid=`uci -q get wireless.ath2.ssid`
    [ -n "$ath2_ssid" ] && uci -c $MESH_BACK_DIR/ set wireless.ath2.ssid="$ath2_ssid"
    ath2_key=`uci -q get wireless.ath2.key`
    [ -n "$ath2_key" ] && uci -c $MESH_BACK_DIR/ set wireless.ath2.key="$ath2_key"

    guest_name=`uci show wireless | grep wsplcd_unmanaged | cut -d '.' -f 2`
    if [ -n "$guest_name" ]; then
	    disabled=`uci -q get wireless.$guest_name.disabled`
	    [ -n "$disabled" ] && uci -c $MESH_BACK_DIR/ set wireless.$guest_name.disabled="$disabled"
	    guest_ssid=`uci -q get wireless.$guest_name.ssid`
	    [ -n "$guest_ssid" ] && uci -c $MESH_BACK_DIR/ set wireless.$guest_name.ssid="$guest_ssid"
	    guest_encryption=`uci -q get wireless.$guest_name.encryption`
	    [ -n "$guest_encryption" ] && uci -c $MESH_BACK_DIR/ set wireless.$guest_name.encryption="$guest_encryption"
	    guest_key=`uci -q get wireless.$guest_name.key`
	    [ -n "$guest_key" ] && uci -c $MESH_BACK_DIR/ set wireless.$guest_name.key="$guest_key"
	    guest_hidden=`uci -q get wireless.$guest_name.hidden`
	    [ -n "$guest_hidden" ] && uci -c $MESH_BACK_DIR/ set wireless.$guest_name.hidden="$guest_hidden"
    fi

    case $g_product_model in
	"RE-CS-06")
		configure_wifi "ath02" "JDCloudwifi_618_2G" "psk2+ccmp" "JDCwifi_pass618..."
		configure_wifi "ath12" "JDCloudwifi_618_5G" "psk2+ccmp" "JDCwifi_pass618..."
		configure_wifi "ath22" "JDCloudwifi_618_5G" "psk2+ccmp" "JDCwifi_pass618..."
		;;
	"RE-SS-02")
		configure_wifi "ath02" "JDCloudwifi_618_5G" "psk2+ccmp" "JDCwifi_pass618..."
		configure_wifi "ath12" "JDCloudwifi_618_2G" "psk2+ccmp" "JDCwifi_pass618..."
		configure_wifi "ath22" "JDCloudwifi_618_5G" "psk2+ccmp" "JDCwifi_pass618..."
		;;
	*)
		# Default configuration for other device types
		configure_wifi "ath02" "JDCloudwifi_618_5G" "psk2+ccmp" "JDCwifi_pass618..."
		configure_wifi "ath12" "JDCloudwifi_618_2G" "psk2+ccmp" "JDCwifi_pass618..."
		;;
    esac

    uci -c $MESH_BACK_DIR/ commit wireless

    cp $MESH_BACK_DIR/wireless /etc/config/wireless
    if [ $(uci -q get wireless.ath0.wps_pbc) != "" -o $(uci -q get wireless.ath1.wps_pbc) != "" ];then
        sed  -i -E '/wps_pbc|root_distance|qwrap_dbdc_enable|dbdc_enable|qwrap_enable/d' /etc/config/wireless
    fi
    cp $MESH_BACK_DIR/repacd /etc/config/repacd
    cp $MESH_BACK_DIR/wsplcd /etc/config/wsplcd
    cp $MESH_BACK_DIR/ezlbd  /etc/config/ezlbd
    cp $MESH_BACK_DIR/ezmesh /etc/config/ezmesh

    rm $MESH_BACK_DIR/wireless
    rm $MESH_BACK_DIR/repacd
    rm $MESH_BACK_DIR/wsplcd
    rm $MESH_BACK_DIR/ezlbd
    rm $MESH_BACK_DIR/ezmesh
    rmdir $MESH_BACK_DIR
    uci set jdc_ezmesh.ezmesh.enable='0'
    uci commit jdc_ezmesh
    /etc/init.d/jdc_ezmesh stop
    /etc/init.d/ezmesh stop
    /etc/init.d/wsplcd stop
    /etc/init.d/repacd stop
    /etc/init.d/hyfi-bridging stop
    sleep 2 #至少需要两秒。1.等待1095报文通知子路由退出 2.接口jdcapi_mesh.c jd_set_quit_mesh()需要配置mlo参数后统一重启network
    /etc/init.d/network restart
    sleep 60 && [ $(hyctl show | wc -l) -gt 2 ] && /etc/init.d/hyfi-bridging stop &
}


#
######
# mtk # 
######
#
mtk_controller_backups_config()
{
	[ ! -d "$MESH_BACK_DIR" ] && mkdir $MESH_BACK_DIR
	
	if [ -e /etc/map ];then
		cp -r /etc/map  $MESH_BACK_DIR
	fi

}
mtk_quit_controller()
{

	uci set system.@system[0].cap_init='0'
	uci commit system

	if [ -e "$MESH_BACK_DIR" ];then
		if [ -e /etc/map ];then
			cp -r $MESH_BACK_DIR/map  /etc
		fi

		rm -rf $MESH_BACK_DIR
	fi

	#处理百里老mesh第一次升级到新mesh的退出
	[ -f /etc/wireless/mediatek/mt7986-ax6000.dbdc.b0.dat ] && {
		wificonf -f /etc/wireless/mediatek/mt7986-ax6000.dbdc.b0.dat set JDDisabled 2 1
		wificonf -f /etc/wireless/mediatek/mt7986-ax6000.dbdc.b1.dat set JDDisabled 2 1
		#退出control 角色
		wificonf -f /etc/map/mapd_user.cfg set MapMode ''
		wificonf -f /etc/wireless/mediatek/mt7986-ax6000.dbdc.b0.dat set MapMode ''
		wificonf -f /etc/wireless/mediatek/mt7986-ax6000.dbdc.b1.dat set MapMode ''
	}
	#处理鲁班老mesh第一次升级到新mesh的退出
	[ -f /etc/wireless/mediatek/mt7915.dbdc.b0.dat ] && {
		wificonf -f /etc/wireless/mediatek/mt7915.dbdc.b0.dat set JDDisabled 2 1
		wificonf -f /etc/wireless/mediatek/mt7915.dbdc.b1.dat set JDDisabled 2 1
		#退出control 角色
		wificonf -f /etc/map/mapd_user.cfg set MapMode ''
		wificonf -f /etc/wireless/mediatek/mt7915.dbdc.b0.dat set MapMode ''
		wificonf -f /etc/wireless/mediatek/mt7915.dbdc.b1.dat set MapMode ''
	}

	uci set jdc_ezmesh.ezmesh.enable='0'
	uci commit jdc_ezmesh
	/etc/init.d/jdc_ezmesh stop
	/etc/init.d/network restart
}

quilt_agent(){
    export ACTION=pressed && sh -x /etc/rc.button/reset && sleep 5 && export ACTION=released && export SEEN=5 && sh -x /etc/rc.button/reset &
}


