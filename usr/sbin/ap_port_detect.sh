#!/bin/sh

for i in 0 1 2 3 4
do
	ebtables -D INPUT -p ipv4 -i eth${i} --ip-proto 17 --ip-dport 68 2>/dev/null
	ebtables -I INPUT -p ipv4 -i eth${i} --ip-proto 17 --ip-dport 68
done

/sbin/udhcpc -s /usr/share/udhcpc/check.script -B -t 3 -T 3 -n -q -i br-lan 2>/dev/null

dhcp_server_flag=`cat /tmp/.dhcp-server-test.txt 2>/dev/null`
[ "$dhcp_server_flag" = "YES" ] && {
	interface=`ebtables -t filter -L --Lc |grep udp |grep dport |grep 68 |grep -v "pcnt = 0"|awk -F ' ' '{print $4}'`

	case "$interface" in
	"eth0")
		echo "1"
	;;
	"eth1")
		echo "2"
	;;
	"eth2")
		echo "3"
	;;
	"eth3")
		echo "4"
	;;
	"eth4")
		echo "5"
	;;

	esac	
}

for i in 0 1 2 3 4
do                
        ebtables -D INPUT -p ipv4 -i eth${i} --ip-proto 17 --ip-dport 68
done

exit 0
