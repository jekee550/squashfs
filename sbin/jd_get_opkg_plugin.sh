#!/bin/ash
sed -ne '/^Package:[[:blank:]]*/ {
	s///
	h
}
/user installed/ {
	g
	p
}' /opt/usr/lib/opkg/status
