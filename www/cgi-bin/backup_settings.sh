#!/bin/sh
return 0
curTime=`date "+%Y%m%d%H%M%S"`

echo "Pragma: no-cache\n"
echo "Cache-control: no-cache\n"
echo "Content-type: application/x-targz"
echo "Content-Disposition: attachment; filename=\"backup_${curTime}.tar.gz\""
echo ""

/sbin/sysupgrade -b - 2>/dev/null
