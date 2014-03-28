#!/bin/sh
rm -rf /var/cfengine/recipes
rm -rf /var/cfengine/inputs/*
cp -rf common/masterfiles/* /var/cfengine/inputs/
cp -rf masterfiles/* /var/cfengine/inputs/
cp -rf common/recipes /var/cfengine/
cp -rf recipes /var/cfengine/
echo cf-agent -K
