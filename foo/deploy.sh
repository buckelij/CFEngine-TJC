#!/bin/sh
#deploy.sh - copies common and specific configuration into place
#to deploy and activate in one step, run: `deploy.sh`
rm -rf /var/cfengine/recipes
rm /var/cfengine/inputs/*
cp common/masterfiles/* /var/cfengine/inputs
cp -f masterfiles/* /var/cfengine/inputs
cp -rf recipes /var/cfengine/
echo cf-agent -K
