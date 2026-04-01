#!/bin/sh

[ -z "$1" ] && sleep 6

echo 0 > /sys/class/leds/led_b1/brightness
echo 0 > /sys/class/leds/led_g1/brightness
echo 0 > /sys/class/leds/led_r1/brightness

while true
do

echo 0 > /sys/class/leds/led_r1/brightness
echo 1 > /sys/class/leds/led_b1/brightness
echo 0 > /sys/class/leds/led_g1/brightness

sleep 1

echo 0 > /sys/class/leds/led_r1/brightness
echo 0 > /sys/class/leds/led_b1/brightness
echo 1 > /sys/class/leds/led_g1/brightness

sleep 1

echo 0 > /sys/class/leds/led_b1/brightness
echo 0 > /sys/class/leds/led_g1/brightness
echo 1 > /sys/class/leds/led_r1/brightness

sleep 1

done

