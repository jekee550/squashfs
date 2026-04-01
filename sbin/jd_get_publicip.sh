#!/bin/sh

is_exist=$(ps|grep jdc_update_public_ip|grep -v grep|wc -l)
[ "$is_exist" != "0" ] && killall -9 jdc_update_public_ip
jdc_update_public_ip &

