#!/bin/bash

chmod 700 /usr/local/tomcat/ssl/password.txt
cat $(pwd)/password.txt >> /usr/local/tomcat/ssl/password.txt
chmod 500 /usr/local/tomcat/ssl/password.txt
rm -rf $(pwd)/password.txt

# do we need to process any service templates for UI to CAS communications
if [ -d "/opt/tomcat/webapps/${TOMCAT_DOCROOT:-${APP_SERVER_NAME}}/WEB-INF/classes/config/service-template" ] ; then
    /var/tmp/ndsuser/process-service-template.sh
fi