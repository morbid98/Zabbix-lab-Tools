#!/bin/bash
zabxapch="/etc/httpd/conf.d/zabbix.conf"
zabxconf="/etc/zabbix/zabbix_server.conf"
echo "installing MariaDB and stuff"
yum install mariadb mariadb-server vim net-tools  -y -q 
echo "installing zabbix"
yum install http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm -y -q
yum install zabbix-server-mysql zabbix-web-mysql zabbix-java-gateway -y -q
echo "instaling zabbix-agent"
yum install zabbix-agent -y -q
systemctl start zabbix-agent
systemctl start zabbix-java-gateway
echo "configuring the DB"
/usr/bin/mysql_install_db --user=mysql
systemctl start mariadb
mysql --user=root -e "create database zabbix character set utf8 collate utf8_bin;"
mysql --user=root -e 'grant all privileges on zabbix.* to zabbix@localhost identified by "128612";'
echo "configuring Zabbix"
zcat /usr/share/doc/zabbix-server-mysql-*/create.sql.gz | mysql -uzabbix -p128612 zabbix
sed -i 's/# JavaGateway=/JavaGateway=192.168.56.2/' $zabxconf
sed -i 's/# StartJavaPollers=/StartJavaPollers=5/' $zabxconf
sed -i 's/# DBPassword=/DBPassword=128612/' $zabxconf
systemctl start zabbix-server
sed -i '/alias/d' $zabxapch
cat $zabxapch |grep DocumentRoot
cr=$?
if [ $cr -eq 0 ];
then
	echo "DocumentRoot already found,skipping"
else	
	sed -i '3aDocumentRoot /usr/share/zabbix/' $zabxapch
fi
sed -i 's/# php_value/php_value/g' $zabxapch
sed -i 's/Riga/Minsk/g' $zabxapch
cat << EOF> '/etc/zabbix/web/zabbix.conf.php'
<?php
// Zabbix GUI configuration file.
global \$DB;

\$DB['TYPE']     = 'MYSQL';
\$DB['SERVER']   = 'localhost';
\$DB['PORT']     = '0';
\$DB['DATABASE'] = 'zabbix';
\$DB['USER']     = 'zabbix';
\$DB['PASSWORD'] = '128612';

// Schema name. Used for IBM DB2 and PostgreSQL.
\$DB['SCHEMA'] = '';

\$ZBX_SERVER      = 'localhost';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = 'Zabbix server';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOF
systemctl start httpd