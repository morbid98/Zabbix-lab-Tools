#!/bin/bash
# Who have access to API
zbxUser='Admin' #Make user with API access and put name here
# His pass
zbxPass='zabbix' #Make user with API access and put password here
# API location
zbxAPI='http://192.168.56.2/zabbix/api_jsonrpc.php'
agentIP=`ifconfig enp0s8 | grep inet | awk '{print $2}' | cut -d':' -f2`
agentHost=$1
# Get auth token from zabbix
curlOutput=`curl -sS -i -X POST -H 'Content-Type: application/json-rpc' -d "{\"params\": {\"password\": \"$zbxPass\", \"user\": \"$zbxUser\"}, \"jsonrpc\":\"2.0\", \"method\": \"user.login\", \"id\": 0}" $zbxAPI`
authToken=`echo $curlOutput| sed -n 's/.*result":"\(.*\)",.*/\1/p'`
#echo $authToken
#Getting OS Linux ID
templ=`curl -sS -i -X POST -H 'Content-Type: application/json-rpc' -d "{\"jsonrpc\":\"2.0\", \"method\": \"template.get\",\"params\":{ \"filter\": {\"host\" : [ \"Template OS Linux\"] } }, \"auth\":\"$authToken\",  \"id\": 1}" $zbxAPI`
templid=`echo $templ| grep -oP '(?<=templateid":")[^ ]*' | cut -f1 -d"\""`
echo $templid
#Getting Linux Servers ID
group=`curl -sS -i -X POST -H 'Content-Type: application/json-rpc' -d "{\"jsonrpc\":\"2.0\", \"method\": \"hostgroup.get\",\"params\":{ \"filter\": {\"name\" : [ \"Linux Servers\"] } }, \"auth\":\"$authToken\",  \"id\": 2}" $zbxAPI`
groupid=`echo $group|grep -oP '(?<=id":)[^ ]*' | cut -f1 -d"\"" | cut -c-1`
echo $groupid
#Creating host
curl -sS -i -X POST -H 'Content-Type: application/json-rpc' -d "{\"jsonrpc\":\"2.0\", \"method\": \"host.create\",\"params\": { \"host\": \"$agentHost\", \"interfaces\": [ { \"type\": 1, \"main\": 1,\"useip\": 1,\"ip\": \"$agentIP\",\"dns\":\"\",\"port\": 10050 } ],\"groups\": [ {\"groupid\": \"$groupid\"} ],\"templates\": [ {\"templateid\": \"$templid\"} ]},\"auth\":\"$authToken\", \"id\": 3}" $zbxAPI
# Get all monitored and problem state triggers
curlData="{\"jsonrpc\": \"2.0\", \"method\": \"user.logout\", \"params\": [], \"auth\":\"$authToken\", \"id\": 4}"
curlOutput=`curl -sS -i -X POST -H 'Content-Type: application/json-rpc' -d "$curlData" $zbxAPI`
       