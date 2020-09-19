# gsuiteRadius - GSuite Radius Auth in Docker

## About

* Docker compose build for freeradius, daloradius, apache2, php, 802.1x auth(EAP-TTLS) via GSuite sLDAP, mac-auth based on latest Ubuntu LTS.
* Includes separate MariaDB-Server 10.3 build with radius schema
* access via `your-ip-or-url/daloradius`
* User: `administrator` Password: `radius`

## Variables

* .env file for changing most configuration options

### RADIUS_REALM
standard value: *acme.com*
### RADIUS_SECRET
standard value: *testing123*

### MYSQL_USER
standard value: *raduser*
### MYSQL_PASSWORD
standard value: *radpass*
### MYSQL_HOST
standard value: *acme_mysql*
### MYSQL_PORT
standard value: *3306*
### MYSQL_DATABASE
standard value: *radius*
### MYSQL_ROOT_PASSWORD
standard value: *t00rPaSs*
### TZ
standard value: *America/Chicago* - [see List of tz time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

* ./radius/conf directory contains configuration files with required edits.  Running `grep -r '# <-' radius/conf/*` will display the files and settings to change.

---
### Certificates
Generic certificates provided for configuration reference but not guaranteed.  A new self-signed certificate authority and server certificates
can be created by following the instructions in the /etc/freeradius/3.0/certs/ directory of the radius container.

---
## Docker-compose example


```yaml
version: '3'

services:
  radius_server:
    container_name: ${COMPOSE_PROJECT_NAME}_radius
    hostname: radius.acme.com
    restart: always
    build:
      context: ./radius
      args:
        - DB_IP=${DB_IP}
        - MYSQL_PASSWORD=${MYSQL_PASSWORD}
        - MYSQL_USER=${MYSQL_USER}
        - MYSQL_HOST=${MYSQL_HOST}
        - MYSQL_PORT=${MYSQL_PORT}
        - MYSQL_DATABASE=${MYSQL_DATABASE}
        - RADIUS_REALM=${RADIUS_REALM}
        - RADIUS_SECRET=${RADIUS_SECRET}
        - RAD_USER=${RAD_USER}
        - RAD_GROUP=${RAD_GROUP}
        - RAD_LOG_DIR=${RAD_LOG_DIR}
    networks:
      rad_vlan:
        ipv4_address: ${RADIUS_IP}
    ports:
      - "80:80/tcp"
      - "1812:1812/udp"
      - "1813:1813/udp"
    volumes:
      - ./radius/conf/clients.conf:/etc/freeradius/3.0/clients.conf
      - ./radius/conf/set_group_vlan:/etc/freeradius/3.0/policy.d/set_group_vlan
      - ./radius/conf/eap:/etc/freeradius/3.0/mods-available/eap
      - ./radius/conf/ldap:/etc/freeradius/3.0/mods-available/ldap
    links:
      - mysql_db:database
    depends_on:
      - "mysql_db"

  mysql_db:
    container_name: ${COMPOSE_PROJECT_NAME}_mysql
    hostname: mysql.acme.com
    restart: always
    build:
      context: ./mariadb
      args:
        - DB_IP=${DB_IP}
        - MYSQL_CONTAINER_USER=mysql
        - MYSQL_CONTAINER_GROUP=mysql
        - MYSQL_DATA_DIR=${MYSQL_DATA_DIR}
        - MYSQL_LOG_DIR=${MYSQL_LOG_DIR}
        - MYSQL_PASSWORD=${MYSQL_PASSWORD}
        - RADIUS_IP=${RADIUS_IP}
    networks:
      rad_vlan:
        ipv4_address: ${DB_IP}
    volumes:
      - ./mariadb/data:${MYSQL_DATA_DIR}
      - ./mariadb/log/:${MYSQL_LOG_DIR}
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_CONTAINER_USER: "mysql"
      MYSQL_CONTAINER_GROUP: "mysql"
      MYSQL_DATABASE: ${MYSQL_DATABASE}

networks:
  rad_vlan:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: ${VLAN_SUBNET}
```