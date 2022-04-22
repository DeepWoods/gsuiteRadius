FROM ubuntu:20.04
LABEL maintainer="DeepWoods"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_RFC3339="1970-01-01T00:00:00Z"
ARG VCS_REF
ARG VERSION
ARG MYSQL_USER
ARG MYSQL_PASSWORD
ARG MYSQL_HOST
ARG MYSQL_PORT
ARG MYSQL_DATABASE
ARG RADIUS_SECRET
ARG RADIUS_REALM
ARG DB_IP
ARG CERT_HOST
ARG TZ

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.vendor="DeepWoods Creations"
LABEL org.label-schema.build-date=$BUILD_RFC3339
LABEL org.label-schema.name="deepwoods/gsuiteRadius"
LABEL org.label-schema.description="Docker image with freeradius, daloradius, apache2, php, 802.1x auth(EAP-TTLS) via GSuite sLDAP, mac-auth. MariaDB-Server in a separate container."
LABEL org.label-schema.url="https://hub.docker.com/r/deepwoods/gsuiteRadius"
LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL org.label-schema.version=$VERSION

STOPSIGNAL SIGKILL

ENV MYSQL_USER=${MYSQL_USER:-raduser}
ENV MYSQL_PASSWORD=${MYSQL_PASSWORD:-radpass}
ENV MYSQL_HOST=${MYSQL_HOST:-192.168.5.6}
ENV MYSQL_PORT=${MYSQL_PORT:-3306}
ENV MYSQL_DATABASE=${MYSQL_DATABASE:-radius}
ENV RADIUS_SECRET=${RADIUS_SECRET:-testing123}
ENV RADIUS_REALM=${RADIUS_REALM:-acme.com}
ENV DB_IP=${DB_IP:-192.168.5.6}
ENV CERT_HOST=${CERT_HOST:-certs.acme.com}

ENV TZ=${TZ:-America/Chicago}

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
    apt-utils \
    tzdata \
    apache2 \
    libapache2-mod-php \
    cron \
    freeradius-config \
    freeradius-utils \
    freeradius \
    freeradius-common \
    freeradius-mysql \
    freeradius-ldap \
    openssh-client \
    rsync \
    net-tools \
    php \
    php-common \
    php-gd \
    php-curl \
    php-mail \
    php-mail-mime \
    php-db \
    php-mysql \
    mariadb-client \
    libmysqlclient-dev \
    supervisor \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && update-ca-certificates -f \
    && mkdir -p /tmp/pear/cache \
    && wget http://pear.php.net/go-pear.phar \
    && php go-pear.phar \
    && rm go-pear.phar \
    && pear channel-update pear.php.net \
    && pear install -a -f DB \
    && pear install -a -f Mail \
    && pear install -a -f Mail_Mime

ENV DALO_VERSION 1.1-2

RUN wget https://github.com/lirantal/daloradius/archive/"$DALO_VERSION".zip \
    && unzip "$DALO_VERSION".zip \
    && rm "$DALO_VERSION".zip \
    && mv daloradius-"$DALO_VERSION" /var/www/html/daloradius \
    && chown -R www-data:www-data /var/www/html/daloradius \
    && chmod 644 /var/www/html/daloradius/library/daloradius.conf.php

EXPOSE 1812 1813 80

COPY supervisor-apache2.conf /etc/supervisor/conf.d/apache2.conf
COPY supervisor-freeradius.conf /etc/supervisor/conf.d/freeradius.conf
COPY ./conf/default /etc/freeradius/3.0/sites-available/default
COPY ./conf/inner-tunnel /etc/freeradius/3.0/sites-available/inner-tunnel
COPY ./conf/cache /etc/freeradius/3.0/mods-available/cache
#COPY ./conf/queries.conf /etc/freeradius/3.0/mods-config/sql/main/mysql/queries.conf
#COPY ./conf/eap /etc/freeradius/3.0/mods-available/eap
#COPY ./conf/ldap /etc/freeradius/3.0/mods-available/ldap
#COPY ./conf/set_group_vlan /etc/freeradius/3.0/policy.d/set_group_vlan
COPY ./certs/ /etc/freeradius/3.0/certs/

COPY init.sh /rad/
COPY supervisor.conf /etc/

CMD ["sh", "/rad/init.sh"]
