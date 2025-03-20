ARG TAG=develop
ARG REGISTRY=lg-bld-cont01.development.local:8443/nds-app-servers

FROM ${REGISTRY}/redis:${TAG}
MAINTAINER Richard Tearle (richard.tearle@northgateps.com)

ARG VERSION
ARG DATETIME

LABEL maintainer="richard.tearle@northgateps.com"\
      org.label-schema.name="Revenue Scotland"\
      org.label-schema.description="Redis Server for Revenue Scotland"\
      org.label-schema.vendor="Northgate Public Services"\
      org.label-schema.version="${VERSION}" \
      org.label-schema.schema-version="1.0"

USER root
RUN <<EOT
	set -e
	groupadd -r redis_user -g 2001 
	useradd -u 2001 -r -g redis_user -s /sbin/nologin -m -c "Docker image user" redis_user 2>/dev/null
	find / -user svc_user -exec chown redis_user {} \; 2>/dev/null || true
	find / -group svc_user -exec chgrp redis_user {} \; 2>/dev/null || true
EOT
USER redis_user

