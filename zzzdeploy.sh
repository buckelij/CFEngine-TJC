#!/bin/bash
# Usage: ./zzzdeploy.sh ConfigSetName
# Prompts for a user and password to use for scp and then scps to /root/<ConfigSetName>
# prompts for a user and password to launch clusterssh (cssh) to connect to those machines
#  (you can install clusterssh from the EPEL repository)
#
# Elijah Buck 12Nov2012

if [ -f "./$1/masterfiles/promises.cf" ]; then

cd ..
CFDIR=`pwd`"/cfengine/$1"

#abort if common isn't included in deploy.sh
grep -q common "$CFDIR/deploy.sh"
if [ $? -ne 0 ]
 then 
  echo "deploy.sh does not include common configurations. aborting."
  exit 1
fi

#grab domain from cfengine config
domain=$(grep '"domain".*string.*=>' ./cfengine/$1/masterfiles/promises.cf  |sed -e 's/^.*domain.*string.*=>//' | sed -e 's/[ ",]//g')

#awk grabs the block between servers_all and the closing bracket
#sed deletes: whitespace, 'servers_all' line, stray chars, blank lines, substitutes underscore for dash in hostnames
hosts=$(awk '/"servers_all"/,/ *};/' ./cfengine/$1/masterfiles/promises.cf   \
            | sed 's/[ \t]//g' | sed 's/"servers_all.*//' | sed 's/[",};]//g' | sed 's/_/-/' |sed '/^$/d' \
            | sed "s/$/.$domain/"| sed -e :a -e '$!N; s/\n/ /; ta')

#but if backend_all is defined, we have to ssh to a backend address
if [[ $(grep backend_all ./cfengine/$1/masterfiles/promises.cf) ]]; then
	hosts=$(awk '/"backend_all"/,/ *};/' ./cfengine/$1/masterfiles/promises.cf \
              | sed 's/[ \t]//g' | sed 's/"backend_all.*//' | sed 's/[",};]//g' | sed 's/_/-/' | sed '/^$/d' \
              | sed -e :a -e '$!N; s/\n/ /; ta')
fi


if [ $# -eq 2 ]; then
	if [ $2 == "ssh" ]; then
	  cssh $hosts &
	  exit
	fi
	if [ $2 == "list" ]; then
	  echo $hosts
	  exit
	fi
fi

echo "==============================================================================="
echo "zzzdeploy: scp a cfengine configuration and open a cssh session"
echo "=>  Parses the promises.cf file for the specified configuration and connects to"
echo "         hosts listed in the servers_all slist or backend_all slist"
echo "=>Found the following hosts for configuration $1: $hosts"
echo "=>You will be prompted for credentials"
echo "=>If you just want ssh run: ./zzzdeployRemote.sh ConfigSetName ssh"
echo "=>If you just want to list hosts run: ./zzzdeployRemote.sh ConfigSetName list"


#thanks internet
function expect_password {
    expect -c "\
    set timeout 90
    set env(TERM)
    spawn $1
    expect \"password:\"
    send \"$PASS\r\"
    expect eof
  "
}

read -p "USER:" USER
read -p "PASS:" -s PASS
for host in $hosts
do
expect_password "sh -c \"/usr/bin/ssh -o StrictHostKeyChecking=no -o CheckHostIP=no $USER@$host 'rm -rf /$USER/$1'\""
expect_password "sh -c \"/usr/bin/scp -o StrictHostKeyChecking=no -o CheckHostIP=no -r $CFDIR $USER@$host:/$USER/\""
expect_password "sh -c \"/usr/bin/scp -o StrictHostKeyChecking=no -o CheckHostIP=no -r $CFDIR/../common $USER@$host:/$USER/$1/\""
done


cssh -l $USER $hosts &

cd cfengine

else
echo "Specify the name of the configuration set"
fi
