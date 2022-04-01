#!/bin/bash

if [[ "$1" = "" ]]; then
    echo "Please specify server domain in lower case"
    exit
fi

server=$1

export REALM=${server^^}
export SERVER=$server

sudo apt -qq update -y 

sudo mkdir -p /downloads
sudo mkdir -p /libs

sudo chmod 777 /downloads
sudo chmod 777 /libs

sudo apt -qq install -y wget
sudo apt -qq install -y default-jdk

echo -e "\n******Installing Kafka ***** \n"

wget --quiet https://dlcdn.apache.org/kafka/3.1.0/kafka_2.12-3.1.0.tgz -P /downloads
tar -xvf /downloads/kafka_2.12-3.1.0.tgz -C /libs >/dev/null 2>&1
rm /downloads/kafka_2.12-3.1.0.tgz

export KAFKA_HOME=/libs/kafka_2.12-3.1.0/

echo -e "\n******Installing Spark ***** \n"
wget --quiet https://dlcdn.apache.org/spark/spark-3.2.1/spark-3.2.1-bin-hadoop3.2.tgz -P /downloads
tar -xvf /downloads/spark-3.2.1-bin-hadoop3.2.tgz -C /libs >/dev/null 2>&1

export SPARK_HOME=/libs/spark-3.2.1-bin-hadoop3.2 

wget --quiet https://repo.maven.apache.org/maven2/org/apache/kafka/kafka-clients/3.1.0/kafka-clients-3.1.0.jar -P /downloads
wget --quiet https://repo.maven.apache.org/maven2/org/apache/kafka/kafka-server-common/3.1.0/kafka-server-common-3.1.0.jar -P /downloads
wget --quiet https://repo.maven.apache.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.12/3.2.1/spark-sql-kafka-0-10_2.12-3.2.1.jar -P /downloads
wget --quiet https://repo.maven.apache.org/maven2/org/apache/kafka/kafka_2.9.2/0.8.2.2/kafka_2.9.2-0.8.2.2.jar -P /downloads
wget --quiet https://repo.maven.apache.org/maven2/org/apache/spark/spark-streaming-kafka-0-10_2.12/3.2.1/spark-streaming-kafka-0-10_2.12-3.2.1.jar -P /downloads
wget --quiet https://repo.maven.apache.org/maven2/org/apache/spark/spark-token-provider-kafka-0-10_2.12/3.2.1/spark-token-provider-kafka-0-10_2.12-3.2.1.jar -P /downloads
wget --quiet https://repo.maven.apache.org/maven2/org/apache/commons/commons-pool2/2.9.0/commons-pool2-2.9.0.jar -P /downloads

mv /downloads/*.jar $SPARK_HOME/jars

echo -e "\n****** Not starting kafka or zookeeper ***** \n"
# sudo $KAFKA_HOME/bin/zookeeper-server-start.sh $KAFKA_HOME/config/zookeeper.properties &
# sudo $KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties &

sudo apt -qq install -y ldap-utils
sudo apt -qq install -y krb5-kdc krb5-admin-server krb5-user

sudo nslookup $SERVER

echo -e "\n********* creating krb5.conf ******** \n"

sudo rm -rf /etc/krb5.conf
sudo touch /etc/krb5.conf
sudo chmod 777 /etc/krb5.conf
sudo echo -e "[libdefaults]\n\tdefault_realm = $REALM\n\n[realms]\n\t$REALM = {\n\tkdc = $SERVER\n\tadmin_server = $SERVER\n}" >> /etc/krb5.conf

echo -e "\n********* creating kdc.conf ******** \n"
sudo chmod 777 /var/log
sudo touch /var/log/krb5kdc.log
sudo chmod 777 /var/log/krb5kdc.log

sudo mkdir -p /etc/krb5kdc/
sudo chmod 777 /etc/krb5kdc

sudo rm -rf /etc/krb5kdc/kdc.conf
sudo touch /etc/krb5kdc/kdc.conf
sudo chmod 777 /etc/krb5kdc/kdc.conf

sudo echo -e "[kdcdefaults]\n\tkdc_listen = 78\n\tkdc_tcp_listen = 78\n\n[realms]\n\t$REALM = {\n\t\tkadmind_port = 749\n\t\tmax_life = 12h 0m 0s\n\t\tmax_renewable_life = 7d 0h 0m 0s\n\t\tmaster_key_type = aes256-cts\n\t\tsupported_enctypes = aes256-cts:normal aes128-cts:normal\n\t}\n\n[logging]\n\tkdc = FILE:/var/log/krb5kdc.log\n\tadmin_server = FILE:/var/log/kadmin.log\n\tdefault = FILE:/var/log/krb5lib.log" >> /etc/krb5kdc/kdc.conf

echo -e "\n********* creating master key ******** \n"

sudo rm -rf /var/lib/krb5kdc/principal
sudo chmod 777 /var/lib/krb5kdc
sudo chmod 777 /var/lib/krb5kdc/principal

sudo kdb5_util create -r $REALM -s -P password

echo -e "\n********* adding principal  ******** \n"
sudo rm -rf /etc/security/keytabs 
sudo mkdir /etc/security/keytabs
sudo chmod 777 /etc/security/keytabs

sudo kadmin.local -q "addprinc -pw password kafka/kafka@$REALM" 
sudo kadmin.local -q "ktadd -k /etc/security/keytabs/kafka.keytab kafka/kafka@$REALM"
sudo klist -kte /etc/security/keytabs/kafka.keytab

echo -e "\n********* starting krb services  ******** \n"

sudo krb5kdc restart
sudo kadmin restart

echo -e "\n********* DONE  ******** \n"


