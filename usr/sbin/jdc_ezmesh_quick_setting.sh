#!/bin/sh

ifname1=$1
ifname2=$2
ifname3=$3



product_name=$(. /lib/ipq806x.sh && echo $(ipq806x_product_name)|tr -d '\n')
if [ "$product_name" == "RE-CS-03" -o  "$product_name" == "RE-OS-03U" -o "$product_name" == "jdc-ss01" ];then
    /sbin/wifi up wifi0 ath0 ath06
    /sbin/wifi up wifi1 ath1
elif [ "$product_name" == "RE-SS-02" ];then
    /sbin/wifi up wifi2 ath2 ath26
    /sbin/wifi up wifi0 ath0
    /sbin/wifi up wifi1 ath1
elif [ "$product_name" == "RE-CS-06" ];then
    /sbin/wifi multi_up wifi0 ath0
    /sbin/wifi multi_up wifi1 ath1 ath16
fi

echo "++++++++++++++++++++++++++++++$0 END+++++++++++++++++++++++++++++ " > /dev/console


