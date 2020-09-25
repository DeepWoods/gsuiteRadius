# gsuiteRadius - RADIUS GSuite Auth in Docker

## About
* Docker compose build providing freeradius, daloradius, apache2, php, 802.1x auth(EAP-TTLS) via GSuite sLDAP, mac-auth based on latest Ubuntu LTS.
* Includes separate MariaDB-Server 10.3 build with radius schema
* access via `your-ip-or-url/daloradius`
* User: `administrator` Password: `radius`

## Installation
1. [Install docker-compose](https://docs.docker.com/compose/install/#install-compose).

2. Clone this repository: `git clone https://github.com/DeepWoods/gsuiteRadius.git .`

3. Modify configuration:
- Read over and edit variables in the .env file.
- Replace all occurrences of acme.com with your GSuite domain.
- Verify and edit ./radius/conf/ldap to reflect your GSuite LDAP credentials, certificate files, and base_dn settings.
- The file ./radius/conf/set_group_vlan should be changed to assign VLAN ID's based on group membership lookup in GSuite.
- NAS devices can be added in ./radius/conf/clients.conf or added via web interface(daloradius) to the SQL database.

4. Build the images and run the services:

        docker-compose up


## Variables
* .env file for changing most configuration options
* Server certificates and credentials in ./radius/conf/ files.

##### RADIUS_REALM
default value: *acme.com*
##### RADIUS_SECRET
default value: *testing123*
##### MYSQL_USER
default value: *raduser*
##### MYSQL_PASSWORD
default value: *radPass*
##### MYSQL_HOST
default value: *acme_mysql*
##### MYSQL_PORT
default value: *3306*
##### MYSQL_DATABASE
default value: *radius*
##### MYSQL_ROOT_PASSWORD
default value: *t00rPaSs*
##### TZ
default value: *America/Chicago* - [see List of tz time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)


---
## Configuration
* ./radius/conf directory contains configuration files with required edits. Pay particular attention editing the ldap file with your GSuite LDAP information.
Running `grep -r '# <-' radius/conf/*` will display the files and settings to change.

### Certificates
Generic certificates provided for configuration reference but not guaranteed.  A new self-signed certificate authority and server certificates
can be created by following the instructions in the /etc/freeradius/3.0/certs/ directory of the radius container.

How to use Let's Encrypt public CA certificate for Freeradius can be found here: https://framebyframewifi.net/2017/01/29/use-lets-encrypt-certificates-with-freeradius/

### Google LDAP Client
Client certificate and client access credentials are required to allow Freeradius to query your GSuite directory.  Information and instructions can be found 
here: https://support.google.com/a/topic/9048334?hl=en&ref_topic=7556686

---
## Docker-compose example

```yaml
version: '3.1'

services:
  radius_server:
    container_name: ${COMPOSE_PROJECT_NAME}_radius
    hostname: radius.${RADIUS_REALM}
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
        - CERT_HOST=${CERT_HOST}
    secrets:
        - id_rsa
        - Google_sLDAP.crt
        - Google_sLDAP.key
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
    hostname: mariadb.${RADIUS_REALM}
    restart: always
    build:
      context: ./mariadb
      args:
        - DB_IP=${DB_IP}
        - MYSQL_CONTAINER_USER=mysql
        - MYSQL_CONTAINER_GROUP=mysql
        - MYSQL_DATA_DIR=/var/lib/mysql
        - MYSQL_LOG_DIR=/var/log/mysql
        - MYSQL_DATABASE=${MYSQL_DATABASE}
        - MYSQL_USER=${MYSQL_USER}
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

secrets:
  id_rsa:
    file: ./radius/id_rsa.txt
  Google_sLDAP.crt:
    file: ./radius/certs/Google_sLDAP.crt
  Google_sLDAP.key:
    file: ./radius/certs/Google_sLDAP.key
```
