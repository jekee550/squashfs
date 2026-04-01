#!/bin/sh

PROCESS_NAME="/usr/sbin/jdmesh_cmd"
JDMESHCMD_PID="/tmp/.jdmeshcmd.pid"

# Kill the process if PID file exists and is not empty
[ -s $JDMESHCMD_PID ] && kill -9 $(cat $JDMESHCMD_PID)

while true; do
    if ! pgrep -f $PROCESS_NAME > /dev/null; then
        INITIALIZED=$(uci -q get system.@system[0].intialized)
        RE_INIT=$(uci -q get system.@system[0].re_init)
        if [ "$INITIALIZED" = "0" ] && [ "$RE_INIT" = "0" ]; then
            if [ ! -e /tmp/.bootdone ]; then
                if [ "$(cat /tmp/sysinfo/model)" = "JDCloud MT7986a RE-CP-03" -o "$(cat /tmp/sysinfo/product_name)" = "RE-CP-02" ];then
                    sleep 20
                else
                    sleep 60
                fi
            fi
            /usr/sbin/jdmesh_cmd '{"cmd": "fii_set_mesh_add_beacon_oui", "args": {}}' &&
            /usr/sbin/jdmesh_cmd '{"cmd": "fii_search_available_mesh_re_list", "args": {"search":"controller"}}' &
            echo $! > $JDMESHCMD_PID
            #sleep_time=63
        else
            break
        fi
    fi
    sleep 3
    #sleep_time=3
done
