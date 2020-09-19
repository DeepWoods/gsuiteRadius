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
CREATE USER 'radius'@'%' IDENTIFIED BY 'MYSQL_PASSWORD';;
GRANT ALL ON radius.* TO 'radius'@'%';

#CREATE USER 'radius'@'RADIUS_IP' IDENTIFIED BY 'MYSQL_PASSWORD';

# The server can read any table in SQL
#GRANT SELECT ON radius.* TO 'radius'@'RADIUS_IP';

# The server can write to the accounting and post-auth logging table.
#
#GRANT ALL on radius.radacct TO 'radius'@'RADIUS_IP';
#GRANT ALL on radius.radpostauth TO 'radius'@'RADIUS_IP';

# INSERT into radius.radcheck (username,attribute,op,value) values("test@acme.com", "Cleartext-Password", ":=", "test");

FLUSH PRIVILEGES;
