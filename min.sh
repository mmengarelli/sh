#!/bin/bash

if [[ "$1" = "" ]]; then
    echo "Please specify server domain in lower case"
    exit
fi

server=$1

export REALM=${server^^}
export SERVER=$server

echo $REALM

echo -e "\n********* isntalling Kerberos components ******** \n"

sudo rm -rf /var/lib/krb5kdc/*

sudo rm -rf /var/lib/krb5kdc/principal
sudo chmod 777 /var/lib/krb5kdc
sudo chmod 777 /var/lib/krb5kdc/principal

# Remove any existing Krb services
sudo apt -qq remove -y krb5-kdc krb5-admin-server krb5-user

sudo apt -qq install -y ldap-utils
sudo apt -qq install -y krb5-kdc 
# krb5-admin-server krb5-user

sudo nslookup $SERVER


