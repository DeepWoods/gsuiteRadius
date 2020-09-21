##
## admin.sql -- MySQL commands for creating the RADIUS user.
##
##      WARNING: You should change 'localhost' and 'radpass'
##               to something else.  Also update raddb/sql.conf
##               with the new RADIUS password.
##
##      $Id: aff0505a473c67b65cfc19fae079454a36d4e119 $

#
#  Create default administrator for RADIUS
#
CREATE USER 'MYSQL_USER'@'%' IDENTIFIED BY 'MYSQL_PASSWORD';;
GRANT ALL ON MYSQL_DATABASE.* TO 'MYSQL_USER'@'%';

#CREATE USER 'MYSQL_USER'@'RADIUS_IP' IDENTIFIED BY 'MYSQL_PASSWORD';

# The server can read any table in SQL
#GRANT SELECT ON MYSQL_DATABASE.* TO 'MYSQL_USER'@'RADIUS_IP';

# The server can write to the accounting and post-auth logging table.
#
#GRANT ALL on MYSQL_DATABASE.radacct TO 'MYSQL_USER'@'RADIUS_IP';
#GRANT ALL on MYSQL_DATABASE.radpostauth TO 'MYSQL_USER'@'RADIUS_IP';

# INSERT into MYSQL_DATABASE.radcheck (username,attribute,op,value) values("test@acme.com", "Cleartext-Password", ":=", "test");

FLUSH PRIVILEGES;
