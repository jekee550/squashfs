#!/bin/sh

num=`uci -S show jd_plugin 2>/dev/null | grep "=plugin" | wc -l`

num=$((num-1))

function get_ver()
{
    pkg=$1
    ver=""
    
    find=`echo "$pkg" | awk '/plugin[A-Z]$/ {print $1}'`

    if [ -n "${find}" ]
    then
        plugin="mm${find##*plugin}"
        ver=`opkg list | grep "${plugin}" | awk -F[' -'] '{print $4}'`
    else
        ver=`opkg list | grep "$pkg" | awk -F[' -'] '{print $4}'`
    fi
    echo "${ver}"
}

while [ $num -ge 0 ]
do
    uci -S get jd_plugin.@plugin[$num].version >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        name=`uci -S get jd_plugin.@plugin[$num].pin 2>/dev/null`
        v="$(get_ver ${name})"
        uci -S set jd_plugin.@plugin[$num].version=$v >/dev/null 2>&1
        #break
    fi 
    num=$((num-1))
    #echo $num
done

uci -S changes jd_plugin >/dev/null 2>&1
if [ $? -eq 0 ] 
then
    uci -S commit jd_plugin >/dev/null 2>&1
fi

