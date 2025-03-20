ARG TAG=develop
ARG REGISTRY=lg-bld-cont01.development.local:8443/nds-app-servers

FROM ${REGISTRY}/reverse-proxy:${TAG}
MAINTAINER Richard Tearle (richard.tearle@northgateps.com)

ARG VERSION
ARG DATETIME

LABEL maintainer="richard.tearle@northgateps.com"\
      org.label-schema.name="Revenue Scotland"\
      org.label-schema.description="Reverse Proxy Layer for Revenue Scotland"\
      org.label-schema.vendor="Northgate Public Services"\
      org.label-schema.version="${VERSION}" \
      org.label-schema.schema-version="1.0"

USER root

ADD conf/httpd 		/
ADD scratch/cacerts/* 	/usr/local/httpd/ssl/
ADD html 		/var/www/html/
ADD scratch/rules 	/etc/httpd/conf/crs/activated_rules
ADD scratch/public/ 	/var/www/html/
ADD healthcheck.sh 	/usr/local/httpd/bin/

RUN <<EOT
	set -e
	groupadd -r rsuser -g 2001
	useradd -u 2001 -r -g rsuser -G apache,clamupdate -s /sbin/nologin -m -c "Docker image user" rsuser 2>/dev/null
	mkdir -p /var/tmp/rsuser/mod_security/rsuser-ip
	chown -R rsuser:rsuser /var/tmp/rsuser
	chown -R root:root /etc/httpd /var/log/httpd /var/www/html
	chmod -R 777 /var/log/httpd
	chmod -R 770 /var/run/httpd
	chmod -R 555 /etc/httpd/conf /etc/httpd/conf.d /etc/httpd/conf.modules.d /var/www/html /etc/freshclam.conf
	chown -R root:apache /usr/local/httpd/ssl/
	chmod 440 /usr/local/httpd/ssl/*
	rm -f /etc/httpd/conf/crs/activated_rules/modsecurity_crs_41_sql_injection_attacks.conf
	rm -f /etc/httpd/conf/crs/activated_rules/modsecurity_crs_50_outbound.conf
	find / -user svc_user -exec chown rsuser {} \; 2>/dev/null || true
	find / -group svc_user -exec chgrp rsuser {} \; 2>/dev/null || true
EOT

USER rsuser
