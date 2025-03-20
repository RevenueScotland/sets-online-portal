#!/bin/bash

# application specific configuration for this application

progName=$(basename $0)
version=$1
altVersion=${1//./-}
environment=$2
dockerImageName=$3
path=$4
release=$5

if [[ -n "${version}" ]] && [[ -n "${environment}" ]]  && [[ -n "${dockerImageName}" ]]; then
	echo Running Revenue Scotland specific configuration
	APP_EXTERNAL_WEBADDRESS=https://\${DOCKERHOST}:\${PROXY_HTTPS_PORT}
	REDIS_PASS=$(openssl rand -hex 32)
	echo MOD_EVASIVE_WHITELIST='172.*.*.*' >> scratch/${version}/${environment}/additional.env
	echo SELHUB_PUBLISH_PORT=$(allocPort.rb) >> scratch/${version}/${environment}/additional.env
        echo SELHUB_TEST_PORT=$(allocPort.rb) >> scratch/${version}/${environment}/additional.env
	echo SELHUB_SUB_PORT=$(allocPort.rb) >> scratch/${version}/${environment}/additional.env
	echo SELFIREFOX_VNC_PORT=$(allocPort.rb) >> scratch/${version}/${environment}/additional.env
	echo SELFIREFOX_NOVNC_PORT=$(allocPort.rb) >> scratch/${version}/${environment}/additional.env
	echo APP_PORT=$(allocPort.rb) >> scratch/${version}/${environment}/additional.env
	echo APP_EXTERNAL_WEBADDRESS=${APP_EXTERNAL_WEBADDRESS} >> scratch/${version}/${environment}/additional.env
	echo RAILS_ENV=test >> scratch/${version}/${environment}/additional.env
	chmod +x scratch/${version}/${environment}/additional.env
	cp autotest-proxy.env scratch/${version}/${environment}/
	
	echo "# Passwords and other secure information for Revenue Scotland" > scratch/${version}/${environment}/password.env
	if [[ -z "${release}" ]]; then
		echo FL_ENDPOINT_ROOT='http://lg-axway-dev.development.local:43080/communication' >> scratch/${version}/${environment}/password.env
	else
		echo FL_ENDPOINT_ROOT='http://lg-axway-dev.development.local:38080/communication' >> scratch/${version}/${environment}/password.env
	fi
	echo FL_USERNAME='EXTPWSUSER' >> scratch/${version}/${environment}/password.env
	echo FL_PASSWORD='WN1cXnWarb@BIDp' >> scratch/${version}/${environment}/password.env
	
	echo ADDRESS_SEARCH_ENDPOINT='http://oprojects1:36080/communication' >> scratch/${version}/${environment}/password.env
	echo ADDRESS_SEARCH_UID='NADRINT@REVSCOT' >> scratch/${version}/${environment}/password.env
	echo ADDRESS_SEARCH_PWD='N0RTHGATE' >> scratch/${version}/${environment}/password.env

	echo COMPANY_SEARCH_ENDPOINT='https://api.companieshouse.gov.uk' >> scratch/${version}/${environment}/password.env
	echo COMPANY_SEARCH_UID='OF_NbbTBvNjzR8TvcfgjSPlpDs4PdHJx_JO-H7Ib' >> scratch/${version}/${environment}/password.env
	echo COMPANY_SEARCH_PWD='' >> scratch/${version}/${environment}/password.env
	
	echo REDIS_PASS=${REDIS_PASS} >> scratch/${version}/${environment}/password.env
	echo REDIS_CACHE_URL="redis://:${REDIS_PASS}@revscot-redis-${environment}:6379/1" >> scratch/${version}/${environment}/password.env

	# Selenium Firefox VNC password
	echo secret > scratch/${version}/${environment}/vnc-password.txt

        export PROXY_HTTP_PORT=$(allocPort.rb)
        export PROXY_HTTPS_PORT=$(allocPort.rb)
        echo PROXY_HTTP_PORT=${PROXY_HTTP_PORT} >> scratch/${version}/${environment}/env.properties
        echo PROXY_HTTPS_PORT=${PROXY_HTTPS_PORT} >> scratch/${version}/${environment}/env.properties
        echo INT_PROXY_HTTP_PORT=${PROXY_HTTP_PORT} >> scratch/${version}/${environment}/env.properties
        echo INT_PROXY_HTTPS_PORT=${PROXY_HTTPS_PORT} >> scratch/${version}/${environment}/env.properties

	exit 0
else
	echo -e "Usage: $0 ${version} environment dockerImageName"
	echo -e "\t${version}\tnumber must be of the form x.y.build"
	echo -e "\tenvironment\tthe name of the environment"
	echo -e "\tdockerImageName\tthe 'root' name of the docker image, i.e. without esb or ui suffix"
	exit 1
fi
