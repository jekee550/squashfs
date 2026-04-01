#!/bin/sh

function start() {
	for i in 24 25 26 27 28 12; do
	ssdk_sh debug phy set $i 0xd 0x7
	ssdk_sh debug phy set $i 0xe `[ $i -eq 12 ] ||echo 0x8077&& echo 0x8079`

	ssdk_sh debug phy set $i 0xd 0x4007
	#ssdk_sh debug phy set $i 0xe 0x8000
	ssdk_sh debug phy set $i 0xe 0x670
	done

	logger -s "jdclog open eth led OK!"

}

function stop() {
	for i in 24 25 26 27 28 12; do
	ssdk_sh debug phy set $i 0xd 0x7
	ssdk_sh debug phy set $i 0xe `[ $i -eq 12 ] ||echo 0x8077&& echo 0x8079`

	ssdk_sh debug phy set $i 0xd 0x4007
	ssdk_sh debug phy set $i 0xe 0x8000
	#ssdk_sh debug phy set $i 0xe 0x670
	done

	logger -s "jdclog close eth led OK!"

}

function ctl() {
	product=`. /lib/ipq806x.sh && ipq806x_product_name`

	if [ "$product" == "RE-SS-02" ]	
	then
        	enable=`uci -q get system.led_switch.enable`

        	if [ "$enable" == "1" ]
        	then
			start
		else
			stop
        	fi
	fi

}

ctl


