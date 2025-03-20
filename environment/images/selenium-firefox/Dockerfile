ARG REGISTRY=lg-bld-cont01.development.local:8443/docker-hub-proxy-cache/selenium
FROM ${REGISTRY}/node-firefox:4.21.0-20240522

ARG VERSION
ARG DATETIME

LABEL maintainer="richard.tearle@northgateps.com"\
      org.label-schema.name="Revenue Scotland"\
      org.label-schema.description="Selenium-Firefox Layer for Revenue Scotland (testing only)"\
      org.label-schema.vendor="Northgate Public Services"\
      org.label-schema.version="${VERSION}" \
      org.label-schema.schema-version="1.0"

RUN mkdir -p /var/tmp/files
COPY files/* /var/tmp/files/
USER root
RUN chown seluser:seluser -R /var/tmp/files /home/seluser
USER seluser
