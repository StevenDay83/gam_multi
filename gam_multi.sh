#!/bin/bash
# gam_multi.sh
# 
# Utility uses Google Apps Manager for multiple managed G-Suite Organizations
#
# Usage:
# gam_multi.sh [CLIENT ID] [GAM PARAMETERS]
#
# Example: gam_multi.sh acme info domain
#
# Multiple Organization Note:
# To set up a Organization, create a new gam project and copy oauth2.txt, oauth2service.json, and client_secrets.json
# to a subfolder within AUTH_ROOT. The subfolder name will be the client ID.
# These files should be secured appropriately. Make sure the subfolder permissions are set to be read only by the relevant local
# users running gam_multi

echo

GAM_PATH="."
AUTH_ROOT="."
OAUTH2_TXT="oauth2.txt"
OAUTH2_JSON="oauth2service.json"
CLIENT_SECRET="client_secrets.json"
LOCK_FILE="gm.lock"
LOCK_TIMEOUT=30

clean_up () {
	if [ -e $AUTH_ROOT"/"$LOCK_FILE ]; then unlink $AUTH_ROOT"/"$LOCK_FILE; fi
	if [ -e $AUTH_ROOT"/"$OAUTH2_TXT ]; then unlink $AUTH_ROOT"/"$OAUTH2_TXT; fi
	if [ -e $AUTH_ROOT"/"$OAUTH2_JSON ]; then unlink $AUTH_ROOT"/"$OAUTH2_JSON; fi
	if [ -e $AUTH_ROOT"/"$CLIENT_SECRET ]; then unlink $AUTH_ROOT"/"$CLIENT_SECRET; fi
}


if [ $# -lt 2 ]
then
	echo "ERROR: Invalid Arguments"
	echo "Usage: gam_multi.sh [CLIENT ID] [GAM OPTIONS]"
	echo
	exit 1
fi

tenant_name=$1

# Check if lockfile exists

count=0
is_locked=1

# Delay until lock is lifted
until [ $count -eq $LOCK_TIMEOUT ]
do

	if [ -e "gm.lock" ]
	then
		if [ $count -eq 0 ]; then echo -n "Waiting for other requests to finish";
		else
			echo -n "."
		fi
		((count++))
		sleep 1
	else
		is_locked=0
		count=10
		break
	fi
done

echo

if [ $is_locked -eq 0 ]
then
	# Create lock file

	touch $AUTH_ROOT"/"$LOCK_FILE
else
	echo
	echo "ERROR: Lock file timeout exceeded"
	echo "Please try again or delete" $LOCK_FILE
	exit 1
fi

# Copy files locally

if [ -e $AUTH_ROOT"/"$tenant_name"/"$OAUTH2_TXT ] && [ -e $AUTH_ROOT"/"$tenant_name"/"$OAUTH2_JSON ] && [ -e $AUTH_ROOT"/"$tenant_name"/"$CLIENT_SECRET ]
then
	echo All auth files for $tenant_name were found
else
	echo "ERROR: Auth files not found"
	echo "Exiting..."
	clean_up
	exit 1
fi

# Copy auth files and run gam command

cp $AUTH_ROOT"/"$tenant_name"/"$OAUTH2_TXT $AUTH_ROOT
cp $AUTH_ROOT"/"$tenant_name"/"$OAUTH2_JSON $AUTH_ROOT
cp $AUTH_ROOT"/"$tenant_name"/"$CLIENT_SECRET $AUTH_ROOT

# Get gam arguments

gam_arguments=""

for i in "${@:2}"
do
	gam_arguments="${gam_arguments} $i"
done

$GAM_PATH/gam $gam_arguments

clean_up
exit 0
