#!/bin/sh

sqlite3 /etc/audit/audit_info.db << !
delete from audit_app_table where timestamp<strftime('%s','now')-60*60*24*30;
delete from audit_node_table where timestamp<strftime('%s','now')-60*60*24*30;
.q
!
