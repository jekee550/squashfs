#!/bin/sh

is_controller=$1
is_agent=$2

if [ "$is_controller" == "" ];then
    is_controller=0
fi

if [ "$is_agent" == "" ];then
    is_agent=0
fi

if [ "$(uci -q get system.led_switch.enable)" = "0"  ];then
   uci -q set jdc_ezmesh.ezmesh.user_turns_on_led=0
   uci commit jdc_ezmesh
fi

upgrading_updated=$(uci -q get jdc_ezmesh.ezmesh.upgrading_updated)
if [ "$upgrading_updated" = "1" ];then
    rm /etc/wireless_*_agent
    exit 0
fi


cp /rom/etc/config/autorole    /etc/config/autorole
[ -f /etc/config/hyd ] && rm /etc/config/hyd
cp /rom/etc/config/lbd    /etc/config/lbd
cp /rom/etc/config/mesh_app    /etc/config/mesh_app
cp /rom/etc/config/repacd    /etc/config/repacd
cp /rom/etc/config/wsplcd    /etc/config/wsplcd
cp /rom/etc/config/ezlbd    /etc/config/ezlbd
cp /rom/etc/config/ezmesh    /etc/config/ezmesh

if [ -e /lib/ipq806x.sh ];then 
    g_product_model=$(. /lib/ipq806x.sh && echo $(ipq806x_product_name))
elif [ -e /lib/ramips.sh ];then
    g_product_model=$(. /lib/ramips.sh && echo $(ramips_product_name))
else
    g_product_model=$(. /lib/functions.sh && echo $(product_name))
fi

function wifison_2_ezmesh_controller() {

    sed  -i '/unmanaged/d' /etc/config/wireless
    sed  -i '/mld/d' /etc/config/wireless
    sed  -i '/repacd_auto_create_vaps/d' /etc/config/wireless

    if [ "$g_product_model" = "RE-CS-03"  -o "$g_product_model" = "RE-OS-03U" ] ;then
        uci set wireless.wifi0.htmode='HT160'
    #elif [ "$g_product_model" = "RE-CS-06" ];then

    #elif [ "$g_product_model" = "RE-SS-02" ];then

    #elif [ "$g_product_model" =  "jdc-ss01" ];then
    #    uci set wireless.wifi0.htmode='HT160'
    #    uci set wireless.wifi0.channel='0'
    else
        echo " wifison_2_ezmesh_controller here is other wxb device and so on" > /dev/console
    fi
    uci set wireless.wifi0.channel='0'
    if [ "$(uci -q show wireless.bk1)" != "" ];then
        uci delete wireless.bk1
        uci delete wireless.ath15
        uci commit wireless
    else #早于等于JDC02:1.5.50.r2204版本
        if [ "$(uci -q get wireless.qcawifi.wps_pbc_overwrite_ap_settings_all)" == "1"  ];then
            uci set jdc_ezmesh.ezmesh.backhaulssid="BH_$(uci -q get wireless.ath1.ssid)"
            uci set jdc_ezmesh.ezmesh.backhaulkey="BH_$(uci -q get wireless.ath1.key)"
            uci delete wireless.qcawifi
            uci commit wireless
            sed  -i '/backhaul/d' /etc/config/wireless
            sed  -i '/wps_pbc/d' /etc/config/wireless
        fi
    fi

    uci set system.@system[0].cap_init='0'
    uci set jdc_ezmesh.ezmesh.enable='1'
    uci set jdc_ezmesh.ezmesh.role='controller'
    uci commit jdc_ezmesh
    rm /etc/wireless_*_agent
    #sleep 15 && /etc/init.d/jdc_ezmesh start &
}



function wifison_2_ezmesh_agent_ax3000() {
    
    uci  -c /etc/ set wireless_ax3000_agent.wifi0.macaddr=$(uci -q get wireless.wifi0.macaddr)
    uci  -c /etc/ set wireless_ax3000_agent.wifi1.macaddr=$(uci -q get wireless.wifi1.macaddr)
    uci  -c /etc/ set wireless_ax3000_agent.ath0.ssid=$(uci -q get wireless.ath0.ssid)
    uci  -c /etc/ set wireless_ax3000_agent.ath1.ssid=$(uci -q get wireless.ath1.ssid)
    uci  -c /etc/ set wireless_ax3000_agent.ath0.key=$(uci -q get wireless.ath0.key)
    uci  -c /etc/ set wireless_ax3000_agent.ath1.key=$(uci -q get wireless.ath1.key)
    uci  -c /etc/ set wireless_ax3000_agent.ath0.encryption=$(uci -q get wireless.ath0.encryption)
    uci  -c /etc/ set wireless_ax3000_agent.ath1.encryption=$(uci -q get wireless.ath1.encryption)
    capmac6=$(uci -q get wireless.bk3.ssid | awk -F'_' '{print tolower($2)}')
    uci  -c /etc/ set wireless_ax3000_agent.ath06.ssid="Mesh_BH_${capmac6}_ssid"
    uci  -c /etc/ set wireless_ax3000_agent.ath06.key="Mesh_BH_${capmac6}_key"
    
    
    uci  -c /etc/ set wireless_ax3000_agent.@wifi-iface[1].ifnameaddr="ec:e8:7c:$(uci -q get wireless.wifi0.macaddr | cut -d':' -f4-6)"
    uci  -c /etc/ set wireless_ax3000_agent.@wifi-iface[1].ssid="Mesh_BH_${capmac6}_ssid"
    uci  -c /etc/ set wireless_ax3000_agent.@wifi-iface[1].key="Mesh_BH_${capmac6}_key"
    
    uci  -c /etc/ commit wireless_ax3000_agent

}


function wifison_2_ezmesh_agent_zhaoyun() {

    uci  -c /etc/ set wireless_zhaoyun_agent.wifi0.macaddr=$(uci -q get wireless.wifi0.macaddr)
    uci  -c /etc/ set wireless_zhaoyun_agent.wifi1.macaddr=$(uci -q get wireless.wifi1.macaddr)
    uci  -c /etc/ set wireless_zhaoyun_agent.ath0.ssid=$(uci -q get wireless.ath0.ssid)
    uci  -c /etc/ set wireless_zhaoyun_agent.ath1.ssid=$(uci -q get wireless.ath1.ssid)
    uci  -c /etc/ set wireless_zhaoyun_agent.ath0.key=$(uci -q get wireless.ath0.key)
    uci  -c /etc/ set wireless_zhaoyun_agent.ath1.key=$(uci -q get wireless.ath1.key)
    uci  -c /etc/ set wireless_zhaoyun_agent.ath0.encryption=$(uci -q get wireless.ath0.encryption)
    uci  -c /etc/ set wireless_zhaoyun_agent.ath1.encryption=$(uci -q get wireless.ath1.encryption)
    capmac6=$(uci -q get wireless.ath17.ssid | awk -F'-' '{print tolower($2)}')
    uci  -c /etc/ set wireless_zhaoyun_agent.ath16.ssid="Mesh_BH_${capmac6}_ssid"
    uci  -c /etc/ set wireless_zhaoyun_agent.ath16.key="Mesh_BH_${capmac6}_key"

    uci  -c /etc/ set wireless_zhaoyun_agent.@wifi-iface[3].ifnameaddr="ec:e8:7c:$(uci -q get wireless.wifi0.macaddr  | cut -d':' -f4-6)"
    uci  -c /etc/ set wireless_zhaoyun_agent.@wifi-iface[3].ssid="Mesh_BH_${capmac6}_ssid"
    uci  -c /etc/ set wireless_zhaoyun_agent.@wifi-iface[3].key="Mesh_BH_${capmac6}_key"
    
    uci  -c /etc/ commit wireless_zhaoyun_agent
    uci delete wireless.ath17
    uci delete wireless.ath11
    uci commit wireless
}

function wifison_2_ezmesh_agent_arthur() {
    uci  -c /etc/ set wireless_arthur_agent.wifi0.macaddr=$(uci -q get wireless.wifi0.macaddr)
    uci  -c /etc/ set wireless_arthur_agent.wifi1.macaddr=$(uci -q get wireless.wifi1.macaddr)
    uci  -c /etc/ set wireless_arthur_agent.ath0.ssid=$(uci -q get wireless.ath0.ssid)
    uci  -c /etc/ set wireless_arthur_agent.ath1.ssid=$(uci -q get wireless.ath1.ssid)
    uci  -c /etc/ set wireless_arthur_agent.ath0.key=$(uci -q get wireless.ath0.key)
    uci  -c /etc/ set wireless_arthur_agent.ath1.key=$(uci -q get wireless.ath1.key)
    uci  -c /etc/ set wireless_arthur_agent.ath0.encryption=$(uci -q get wireless.ath0.encryption)
    uci  -c /etc/ set wireless_arthur_agent.ath1.encryption=$(uci -q get wireless.ath1.encryption)
    capmac6=$(uci -q get wireless.bk3.ssid | awk -F'_' '{print tolower($2)}')
    if [ "$capmac6" != "" ];then
        uci  -c /etc/ set wireless_arthur_agent.ath06.ssid="Mesh_BH_${capmac6}_ssid"
        uci  -c /etc/ set wireless_arthur_agent.ath06.key="Mesh_BH_${capmac6}_key"

        uci  -c /etc/ set wireless_arthur_agent.@wifi-iface[1].ifnameaddr="ec:e8:7c:$(uci -q get wireless.wifi0.macaddr | cut -d':' -f4-6)"
        uci  -c /etc/ set wireless_arthur_agent.@wifi-iface[1].ssid="Mesh_BH_${capmac6}_ssid"
        uci  -c /etc/ set wireless_arthur_agent.@wifi-iface[1].key="Mesh_BH_${capmac6}_key"
        
        uci  -c /etc/ commit wireless_arthur_agent
    else #早于等于JDC02:1.5.50.r2204版本
            if [  $(uci -q  get wireless.@wifi-iface[2].mode) == "sta"  -a $(uci -q  get wireless.@wifi-iface[3].mode) == "sta"  ];then
                backhaulssid="BH_$(uci -q  get wireless.@wifi-iface[2].ssid)"
                backhaulkey="BH_$(uci -q  get wireless.@wifi-iface[2].key)"
                uci set jdc_ezmesh.ezmesh.backhaulssid=$backhaulssid
                uci set jdc_ezmesh.ezmesh.backhaulkey=$backhaulkey
                uci  -c /etc/ set wireless_arthur_agent.ath06.ssid=$backhaulssid
                uci  -c /etc/ set wireless_arthur_agent.ath06.key=$backhaulkey
                uci  -c /etc/ set wireless_arthur_agent.@wifi-iface[1].ifnameaddr="ec:e8:7c:$(uci -q get wireless.wifi0.macaddr | cut -d':' -f4-6)"
                uci  -c /etc/ set wireless_arthur_agent.@wifi-iface[1].ssid=$backhaulssid
                uci  -c /etc/ set wireless_arthur_agent.@wifi-iface[1].key=$backhaulkey
                uci  -c /etc/ commit wireless_arthur_agent
                uci delete wireless.qcawifi
                uci delete wireless.@wifi-iface[3]
                uci delete wireless.@wifi-iface[2]
                sed  -i '/backhaul/d' /etc/config/wireless
                sed  -i '/wps_pbc/d' /etc/config/wireless
            fi
    fi

}

function wifison_2_ezmesh_agent_athena() {
    uci  -c /etc/ set wireless_athena_agent.wifi0.macaddr=$(uci -q get wireless.wifi0.macaddr)
    uci  -c /etc/ set wireless_athena_agent.wifi1.macaddr=$(uci -q get wireless.wifi1.macaddr)
    uci  -c /etc/ set wireless_athena_agent.wifi2.macaddr=$(uci -q get wireless.wifi2.macaddr)
    uci  -c /etc/ set wireless_athena_agent.ath0.ssid=$(uci -q get wireless.ath0.ssid)
    uci  -c /etc/ set wireless_athena_agent.ath1.ssid=$(uci -q get wireless.ath1.ssid)
    uci  -c /etc/ set wireless_athena_agent.ath2.ssid=$(uci -q get wireless.ath2.ssid)
    uci  -c /etc/ set wireless_athena_agent.ath0.key=$(uci -q get wireless.ath0.key)
    uci  -c /etc/ set wireless_athena_agent.ath1.key=$(uci -q get wireless.ath1.key)
    uci  -c /etc/ set wireless_athena_agent.ath2.key=$(uci -q get wireless.ath2.key)
    uci  -c /etc/ set wireless_athena_agent.ath0.encryption=$(uci -q get wireless.ath0.encryption)
    uci  -c /etc/ set wireless_athena_agent.ath1.encryption=$(uci -q get wireless.ath1.encryption)
    uci  -c /etc/ set wireless_athena_agent.ath2.encryption=$(uci -q get wireless.ath2.encryption)
    capmac6=$(uci -q get wireless.bk3.ssid | awk -F'_' '{print tolower($2)}')
    uci  -c /etc/ set wireless_athena_agent.ath26.ssid="Mesh_BH_${capmac6}_ssid"
    uci  -c /etc/ set wireless_athena_agent.ath26.key="Mesh_BH_${capmac6}_key"

    uci  -c /etc/ set wireless_athena_agent.@wifi-iface[1].ifnameaddr="ec:e8:7c:$(uci -q get wireless.wifi0.macaddr | cut -d':' -f4-6)"
    uci  -c /etc/ set wireless_athena_agent.@wifi-iface[1].ssid="Mesh_BH_${capmac6}_ssid"
    uci  -c /etc/ set wireless_athena_agent.@wifi-iface[1].key="Mesh_BH_${capmac6}_key"
    
    uci  -c /etc/ commit wireless_athena_agent

}


function wifison_2_ezmesh_agent() {

    if [ "$g_product_model" = "RE-CS-03"  -o "$g_product_model" = "RE-OS-03U" ] ;then
        wifison_2_ezmesh_agent_ax3000
    elif [ "$g_product_model" = "RE-CS-06" ];then
        wifison_2_ezmesh_agent_zhaoyun
    elif [ "$g_product_model" = "RE-SS-02" ];then
        wifison_2_ezmesh_agent_athena
    elif [ "$g_product_model" =  "jdc-ss01" ];then
        wifison_2_ezmesh_agent_arthur
    else
        echo " wifison_2_ezmesh_agent here is other wxb device and so on" > /dev/console
    fi

    sed  -i '/unmanaged/d' /etc/config/wireless
    sed  -i '/repacd_auto_create_vaps/d' /etc/config/wireless
    sed  -i '/mld/d' /etc/config/wireless
    uci delete wireless.bk1
    uci delete wireless.bk3
    uci commit wireless
    uci set jdc_ezmesh.ezmesh.enable='1'
    uci commit jdc_ezmesh
    uci set system.@system[0].re_init='0'
    #sleep 15 && /etc/init.d/jdc_ezmesh start &

    
    if [ "$g_product_model" = "RE-CS-03"  -o "$g_product_model" = "RE-OS-03U" ] ;then
        sleep 300 && [ -z "$(ip addr show br-lan | awk '/^[0-9]+: / {}; /inet.*global/ {print $2}' | cut -d'/' -f1)" ] &&  mv -f /etc/wireless_ax3000_agent /etc/config/wireless && rm /etc/wireless_*_agent && /sbin/wifi & 
    elif [ "$g_product_model" = "RE-CS-06" ];then
        sleep 300 && [ -z "$(ip addr show br-lan | awk '/^[0-9]+: / {}; /inet.*global/ {print $2}' | cut -d'/' -f1)" ] && mv -f /etc/wireless_zhaoyun_agent /etc/config/wireless && rm /etc/wireless_*_agent && /sbin/wifi & 
    elif [ "$g_product_model" = "RE-SS-02" ];then
        sleep 300 && [ -z "$(ip addr show br-lan | awk '/^[0-9]+: / {}; /inet.*global/ {print $2}' | cut -d'/' -f1)" ] && mv -f /etc/wireless_athena_agent /etc/config/wireless && rm /etc/wireless_*_agent && /sbin/wifi & 
    elif [ "$g_product_model" =  "jdc-ss01" ];then
        sleep 300 && [ -z "$(ip addr show br-lan | awk '/^[0-9]+: / {}; /inet.*global/ {print $2}' | cut -d'/' -f1)" ] &&  mv -f /etc/wireless_arthur_agent /etc/config/wireless && rm /etc/wireless_*_agent && /sbin/wifi & 
    else
        rm /etc/wireless_*_agent
    fi

}

logger -p user.info "jdc_ezmesh_wifison2ezmesh.sh : is_controller=$is_controller is_agent=$is_agent"

if [ "$is_controller" == "1" ];then
        wifison_2_ezmesh_controller
elif [ "$is_agent" == "1" ];then
        wifison_2_ezmesh_agent
else
    rm /etc/wireless_*_agent
    if [ "$g_product_model" = "RE-CS-06" -a "$(uci -q get  wireless.ath15)" != "" ];then
       #赵云非mesh时清理无线配置文件的mesh相关配置
       sed -i '/repacd_create_ctrl_fbss/d' /etc/config/wireless
       sed -i '/repacd_create_ctrl_bbss/d' /etc/config/wireless
       sed -i '/doth/d' /etc/config/wireless
       sed -i '/wps_pbc/d' /etc/config/wireless
       sed -i '/map/d' /etc/config/wireless
       sed -i '/wds/d' /etc/config/wireless
       sed -i '/interworking/d' /etc/config/wireless
       sed -i '/anqp_elem/d' /etc/config/wireless
       sed -i '/MapBSSType/d' /etc/config/wireless
       sed -i '/dbdc_enable/d' /etc/config/wireless
       uci delete wireless.qcawifi
       uci delete wireless.ath15
       uci commit wireless
    fi
    exit 0
fi


