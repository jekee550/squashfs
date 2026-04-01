#!/bin/sh
PROCESS_MESHCMD="/usr/sbin/jdmesh_cmd"
PROCESS_MESHMONITOR="/usr/sbin/jdc_ezmesh_monitor.sh"

[ -n  "$(pgrep -f $PROCESS_MESHMONITOR)" ] && kill $(pgrep -f $PROCESS_MESHMONITOR)
[ -n  "$(pgrep -f $PROCESS_MESHCMD)" ] && kill $(pgrep -f $PROCESS_MESHCMD)
logger "jdc_web_init.sh ezmesh already stop scan and delete beacon oui"
jdmesh_cmd '{"cmd": "fii_set_mesh_del_beacon_oui", "args": {}}' &
