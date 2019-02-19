#!/bin/bash
apache="apache-tomcat-8.5.37"
echo "Installing stuff"
yum install  -q -y http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm -y -q
yum install zabbix-agent vim unzip java net-tools  zabbix-sender -y -q
if [ -f $apache.zip ]
then
	echo "Tomcat already exists"
else 
	echo "Downloading Tomcat"
	wget -q --progress=bar:force:noscroll http://ftp.byfly.by/pub/apache.org/tomcat/tomcat-8/v8.5.37/bin/$apache.zip 
	echo "Unzipping Tomcat"
	unzip -q $apache.zip 
fi
if [ -f $apache/lib/tomcat-catalina-jmx-remote-8.0.28.jar ]
then
	echo "Jmx Remote already exists" 
else 
	wget -q -P $apache/lib/ http://repo2.maven.org/maven2/org/apache/tomcat/tomcat-catalina-jmx-remote/8.0.28/tomcat-catalina-jmx-remote-8.0.28.jar
fi	
echo "Setting env variables"
cat <<EOF > $apache/bin/setenv.sh
export CATALINA_OPTS=" \
-Dcom.sun.management.jmxremote=true \
-Dcom.sun.management.jmxremote.port=12345 \
-Dcom.sun.management.jmxremote.rmi.port=12346 \
-Dcom.sun.management.jmxremote.authenticate=false \
-Djava.rmi.server.hostname=192.168.56.3 \
-Dcom.sun.management.jmxremote.ssl=false" 
EOF
echo "Configuring static ports for firewall(just incase)"
cat $apache/conf/server.xml |grep JmxRemoteLifecycleListener >> /dev/null
cr=$?
if [ $cr -eq 0 ];
then 
	echo "JmxRemoteLifecycleListener found,skipping"
else	
	sed -i '/ThreadLocalLeak/i<Listener \
	  className="org.apache.catalina.mbeans.JmxRemoteLifecycleListener" \
	  rmiRegistryPortPlatform="8097" \
	  rmiServerPortPlatform="8098" \
	/> ' $apache/conf/server.xml
fi
echo "Giving rights"
chmod +x $apache/bin/*.sh
chown vagrant:vagrant -R $apache/
if [ -f TestApp.war ];
then
	echo "TestApp already exists"
else	
	cp /vagrant/TestApp.war $apache/webapps/
fi
echo "Restarting Tomcat (5 sec cooldown)"
./$apache/bin/startup.sh
sleep 5
echo "Configuring agent"
sed -i 's/127.0.0.1/192.168.56.2/g' /etc/zabbix/zabbix_agentd.conf
echo "Leggo!"
systemctl start zabbix-agent
