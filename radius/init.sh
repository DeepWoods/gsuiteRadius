#!/bin/bash
set -e

echo '#!/bin/bash' > /rad/init.sh
echo 'echo "Initialization error" 1>&2' >> /rad/init.sh

DEBIAN_FRONTEND=noninteractive

#wait for MySQL-Server to be ready
while ! mysqladmin ping -h"$MYSQL_HOST" --silent; do
    sleep 20
done

# Seed Database
#mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql 
mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < /var/www/html/daloradius/contrib/db/mysql-daloradius.sql 

# add ssh key and copy let's encrypt certs
#eval "$(ssh-agent -s)"
#if [ ! -d "/root/.ssh/" ]; then
#    mkdir /root/.ssh
#    ssh-add -k /run/secrets/id_rsa
#    ssh-keyscan $CERT_HOST > /root/.ssh/known_hosts
#    # scp lets encrypt keys from external nginx host
#    scp root@$CERT_HOST:/etc/letsencrypt/live/$CERT_HOST/{privkey.pem,fullchain.pem} /etc/freeradius/3.0/certs/
#    chmod +r /etc/freeradius/3.0/certs/*
#fi

# schedule certificate sync in cron with rsync
#if [ -f "/etc/cron.daily/sync-certs.sh" ]; then
#	cat <<EOF > /etc/cron.daily/sync-certs.sh
##!/bin/sh
#rsync -e 'ssh -i /run/secrets/id_rsa' -Lz root@$CERT_HOST:/etc/letsencrypt/live/$CERT_HOST/{privkey.pem,fullchain.pem} /etc/freeradius/3.0/certs/
#EOF
#chmod +x /etc/cron.daily/sync-certs.sh
#fi

# Enable SQL in freeradius
sed -i 's|driver = "rlm_sql_null"|driver = "rlm_sql_mysql"|' /etc/freeradius/3.0/mods-available/sql 
sed -i 's|dialect = "sqlite"|dialect = "mysql"|' /etc/freeradius/3.0/mods-available/sql
sed -i 's|dialect = ${modules.sql.dialect}|dialect = "mysql"|' /etc/freeradius/3.0/mods-available/sqlcounter                             # avoid instantiation error
sed -i 's|ca_file = "/etc/ssl/certs/my_ca.crt"|#ca_file = "/etc/freeradius/3.0/certs/ca.crt"|' /etc/freeradius/3.0/mods-available/sql    # sql encryption - disabled
sed -i 's|ca_path = "/etc/ssl/certs/"|#ca_path = "/etc/freeradius/3.0/certs/"|' /etc/freeradius/3.0/mods-available/sql                   # sql encryption - disabled
sed -i 's|certificate_file = "/etc/ssl/certs/private/client.crt"|#certificate_file = "/etc/freeradius/3.0/certs/rad_client.crt"|' /etc/freeradius/3.0/mods-available/sql    # sql encryption - disabled
sed -i 's|private_key_file = "/etc/ssl/certs/private/client.key"|#private_key_file = "/etc/freeradius/3.0/certs/rad_client.key"|' /etc/freeradius/3.0/mods-available/sql    # sql encryption - disabled
sed -i 's|tls_required = yes|tls_required = no|' /etc/freeradius/3.0/mods-available/sql        # sql encryption - disabled
sed -i 's|#\s*read_clients = yes|read_clients = yes|' /etc/freeradius/3.0/mods-available/sql 
ln -s /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql
ln -s /etc/freeradius/3.0/mods-available/sqlcounter /etc/freeradius/3.0/mods-enabled/sqlcounter

# Enable status in freeadius
ln -s /etc/freeradius/3.0/sites-available/status /etc/freeradius/3.0/sites-enabled/status

# Enable modules for LDAP auth
ln -s /etc/freeradius/3.0/mods-available/cache /etc/freeradius/3.0/mods-enabled/cache
ln -s /etc/freeradius/3.0/mods-available/ldap /etc/freeradius/3.0/mods-enabled/ldap
ln -s /etc/freeradius/3.0/mods-available/cache_auth /etc/freeradius/3.0/mods-enabled/cache_auth

# add realm
cat <<EOF >> /etc/freeradius/3.0/proxy.conf
realm $RADIUS_REALM {
     User-Name = "%{Stripped-User-Name}"
}
EOF

# Set Database connection
sed -i 's|^#\s*server = .*|server = "'$MYSQL_HOST'"|' /etc/freeradius/3.0/mods-available/sql
sed -i 's|^#\s*port = .*|port = "'$MYSQL_PORT'"|' /etc/freeradius/3.0/mods-available/sql
sed -i 's|^#\s*radius_db = .*|radius_db = "'$MYSQL_DATABASE'"|' /etc/freeradius/3.0/mods-available/sql
sed -i 's|^#\s*password = .*|password = "'$MYSQL_PASSWORD'"|' /etc/freeradius/3.0/mods-available/sql 
sed -i 's|^#\s*login = .*|login = "'$MYSQL_USER'"|' /etc/freeradius/3.0/mods-available/sql

# Daloradius conf
sed -i "s/\$configValues\['CONFIG_DB_HOST'\] = .*;/\$configValues\['CONFIG_DB_HOST'\] = '$MYSQL_HOST';/" /var/www/html/daloradius/library/daloradius.conf.php
sed -i "s/\$configValues\['CONFIG_DB_PORT'\] = .*;/\$configValues\['CONFIG_DB_PORT'\] = '$MYSQL_PORT';/" /var/www/html/daloradius/library/daloradius.conf.php
sed -i "s/\$configValues\['CONFIG_DB_PASS'\] = .*;/\$configValues\['CONFIG_DB_PASS'\] = '$MYSQL_PASSWORD';/" /var/www/html/daloradius/library/daloradius.conf.php 
sed -i "s/\$configValues\['CONFIG_DB_USER'\] = .*;/\$configValues\['CONFIG_DB_USER'\] = '$MYSQL_USER';/" /var/www/html/daloradius/library/daloradius.conf.php
sed -i "s/\$configValues\['CONFIG_DB_NAME'\] = .*;/\$configValues\['CONFIG_DB_NAME'\] = '$MYSQL_DATABASE';/" /var/www/html/daloradius/library/daloradius.conf.php
sed -i "s/\$configValues\['FREERADIUS_VERSION'\] = .*;/\$configValues\['FREERADIUS_VERSION'\] = '3';/" /var/www/html/daloradius/library/daloradius.conf.php

rm -r /rad/*

echo '#!/bin/bash' > /rad/init.sh
echo 'supervisord -c /etc/supervisor.conf' >> /rad/init.sh

supervisord -c /etc/supervisor.conf
