#!/bin/sh

while true
do
	out_segs_1=`awk 'BEGIN {OFS=" "} $1 ~ /Tcp:/ && $2 !~ /RtoAlgorithm/ {print $12}' /proc/net/snmp`
	retrans_segs_1=`awk 'BEGIN {OFS=" "} $1 ~ /Tcp:/ && $2 !~ /RtoAlgorithm/ {print $13}' /proc/net/snmp`
	echo "old out_segs $out_segs_1,retrans_segs $retrans_segs_1"
	sleep 60
	out_segs_2=`awk 'BEGIN {OFS=" "} $1 ~ /Tcp:/ && $2 !~ /RtoAlgorithm/ {print $12}' /proc/net/snmp`
	retrans_segs_2=`awk 'BEGIN {OFS=" "} $1 ~ /Tcp:/ && $2 !~ /RtoAlgorithm/ {print $13}' /proc/net/snmp`
	echo "new out_segs $out_segs_2,retrans_segs $retrans_segs_2"

	if [ "$out_segs_1" -le "$out_segs_2" ] && [ "$retrans_segs_1" -le "$retrans_segs_2" ]; then
		out_segs=$((${out_segs_2} - ${out_segs_1}))
		retrans_segs=$((${retrans_segs_2} - ${retrans_segs_1}))
		echo "out_segs $out_segs, retrans_segs $retrans_segs"
		tcp_retrans_rate=$((($retrans_segs*100)/$out_segs))
		echo "retrans rate:${tcp_retrans_rate}%"
		uci -c /tmp/ set jd_wan_rate.wan.tcp_retrans=$tcp_retrans_rate
		uci -c /tmp/ commit jd_wan_rate
	fi
done

