FROM mariadb:10.3
LABEL maintainer="DeepWoods"

ARG BUILD_RFC3339="1970-01-01T00:00:00Z"
ARG VCS_REF
ARG VERSION
ARG MYSQL_CONTAINER_USER
ARG MYSQL_CONTAINER_GROUP
ARG MYSQL_DATA_DIR
ARG MYSQL_LOG_DIR
ARG MYSQL_DATABASE 
ARG MYSQL_USER 
ARG MYSQL_PASSWORD 
ARG RADIUS_IP
ARG DB_IP

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.vendor="DeepWoods Creations"
LABEL org.label-schema.build-date=$BUILD_RFC3339
LABEL org.label-schema.name="deepwoods/gsuiteRadius"
LABEL org.label-schema.description="Docker image built from MariaDB-Server 10.3 for FreeRadius/Daloradius."
LABEL org.label-schema.url="https://hub.docker.com/r/deepwoods/gsuiteRadius"
LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL org.label-schema.version=$VERSION


COPY my.cnf /etc/mysql/conf.d/mariadb.cnf

COPY sql/*.sql /docker-entrypoint-initdb.d/
COPY certs/* /mysql-certs/

RUN mkdir -p ${MYSQL_LOG_DIR} && \
	usermod -u 1000 ${MYSQL_CONTAINER_USER} && \
 	groupmod -g 1000 ${MYSQL_CONTAINER_GROUP} && \
	chown ${MYSQL_CONTAINER_USER}:${MYSQL_CONTAINER_USER} -R ${MYSQL_DATA_DIR} ${MYSQL_LOG_DIR} /docker-entrypoint-initdb.d && \
	sed -i -e 's@MYSQL_DATABASE@'${MYSQL_DATABASE}'@g' /docker-entrypoint-initdb.d/db_setup.sql && \
	sed -i -e 's@MYSQL_USER@'${MYSQL_USER}'@g' /docker-entrypoint-initdb.d/db_setup.sql && \
	sed -i -e 's@MYSQL_PASSWORD@'${MYSQL_PASSWORD}'@g' /docker-entrypoint-initdb.d/db_setup.sql && \
	sed -i -e 's@RADIUS_IP@'${RADIUS_IP}'@g' /docker-entrypoint-initdb.d/db_setup.sql && \
	chown ${MYSQL_CONTAINER_USER}:${MYSQL_CONTAINER_USER} -R /mysql-certs/

EXPOSE 3306
