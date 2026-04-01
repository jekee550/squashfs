#!/bin/sh
case $1 in
        start)
                tmate -F > /tmp/tmate.log &
		sleep 43200 && killall -9 tmate &
        ;;
        stop)
                killall -9 tmate
                cat /dev/null > /tmp/tmate.log
        ;;
        status)
                cat /tmp/tmate.log
        ;;
	*)
		echo jd_remote start
		echo jd_remote status
		echo jd_remote stop
	;;
esac
