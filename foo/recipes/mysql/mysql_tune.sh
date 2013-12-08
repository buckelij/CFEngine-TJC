#!/bin/bash
# run every time by cfengine to make sure things are in order

MYSQLCMD="/usr/bin/mysql --defaults-extra-file=/root/my-secret.cnf -e"
#check that the zabbix 'status' user exists
if [ ! -e /var/lib/mysql/mysql.sock ] #exit true if mysql isn't running
then
	/bin/true
elif ! `$MYSQLCMD "select user from mysql.user;" | /bin/grep -q status`  
then												
	$MYSQLCMD "create user status@localhost; grant process on *.* to status@localhost;"
else										
	/bin/false
fi
