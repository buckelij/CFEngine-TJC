#!/bin/bash
# deploy.sh
# Tomcat deployment script
#   This script stops tomcat, removes the old WAR, copies the new
#   WAR, then starts tomcat. 
#
#   The 'deploy' user that runs this script will need appropriate sudo permissions:
#     Defaults:deploy !requiretty
#     Defaults:deploy visiblepw
#     %tomcat ALL=(tomcat) NOPASSWD: ALL
#     %tomcat ALL= NOPASSWD: /sbin/service tomcat stop, /sbin/service tomcat start
#
#  18Jan2013 - erb - initial version
#  30Jan2014 - erb - convert to multi
#
# Usage: deploy.sh </PATH/TO/WAR>

#EDIT THESE AS REQUIRED
TOMCAT_USER=tomcat-$(tomcat_multi.tomcat_instance)                #who to sudo as for the copy
TOMCAT_SERVICE=tomcat-$(tomcat_multi.tomcat_instance)             #name of init service script
TOMCAT_INSTANCE=/usr/local/$(tomcat_multi.tomcat_instance)        #tomcat install path (symlink is ok)
PATH=/usr/bin:/bin

#BEGIN
export PATH
cd /tmp
sudo -n -u $TOMCAT_USER id > /dev/null
if ! [[ $? -eq 0 ]]; then
  echo "ERROR: Can't become user $TOMCAT_USER, is sudo set up?"; exit 1
fi

if ! [[ $# -eq 1 ]]; then 
  echo "USAGE: deploy.sh </PATH/TO/WAR>"; exit 1
fi

if ! [[ -d $TOMCAT_INSTANCE/webapps ]]; then
  echo "ERROR: destination not found"; exit 1
fi

#Check if the new WAR exists
WAR_SOURCE=$1
if ! [[ -f $WAR_SOURCE ]]; then
  echo "ERROR: source war missing or wrong file extension"; exit 1
fi

#stop tomcat
sudo /sbin/service $TOMCAT_SERVICE stop
sleep 10
#kill tomcat if it failed to stop
sudo -u $TOMCAT_USER pkill -9 -f -U tomcat java.\*$TOMCAT_INSTANCE
if [[ $? -eq 0 ]]; then
  echo "NOTICE: tomcat did not shutdown cleanly and was killed"
  echo "NOTICE: you may want to double-check the process table"
fi

#remove old war and redeploy
#clean up old wars that are the same, except for case sensitivity
WAR_FILE=`basename $WAR_SOURCE`
WAR_NAME=${WAR_FILE%.*} #just the name, e.g. ROOT
sudo -u $TOMCAT_USER find -H $TOMCAT_INSTANCE/webapps -maxdepth 1 -type f \
    -iname $WAR_NAME.war -execdir rm {} \;
sudo -u $TOMCAT_USER find -H $TOMCAT_INSTANCE/webapps -maxdepth 1 -type d \
    -iname $WAR_NAME -execdir rm -rf {} \;

sudo -u $TOMCAT_USER cp $WAR_SOURCE $TOMCAT_INSTANCE/webapps/
#start tomcat
sudo /sbin/service $TOMCAT_SERVICE start

echo "NOTICE: Done"
