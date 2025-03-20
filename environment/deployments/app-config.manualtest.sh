#!/bin/bash

# application specific configuration for this application

progName=$(basename $0)
version=$1
altVersion=${1//./-}
environment=$2
dockerImageName=$3

function error_exit
{
	echo "${progName}: ${1:-"Unknown Error"}" 1>&2
	exit 1
}

if [[ -n "$version" ]] && [[ -n "$environment" ]]  && [[ -n "$dockerImageName" ]]; then

	# REDIS_PASS word ... 
	REDIS_PASS=QI2R3YJLbfPOxizdLp6wb/c5TZbwax5tNy1CwCj01yeKGiHyYdKe4Jd+f/8nD4RRkF7Jmp7xnAUZ4b46RvvIQ8JTk6LQ0AnLo6yFdC3DJ3G8qcskGj4i3F6pEq7WpFqAeUGm2nAxLprbrVZ4f7GloSC6DWV9ahr4Uvqsjyf/0nk=
	REDIS_PASS_URI=$(echo -ne ${REDIS_PASS} | hexdump -v -e '/1 "%02x"' | sed 's/\(..\)/%\1/g')

	echo Running Revenue Scotland specific configuration
	echo export INT_PROXY_HTTP_PORT=4000 >> scratch/$version/$environment/additional.env
	echo export INT_PROXY_HTTPS_PORT=4001 >> scratch/$version/$environment/additional.env
	echo export PROXY_HTTP_PORT=4000 >> scratch/$version/$environment/additional.env
	echo export PROXY_HTTPS_PORT=4001 >> scratch/$version/$environment/additional.env
	echo export MOD_EVASIVE_WHITELIST=127.0.0.1 >> scratch/$version/$environment/additional.env
	echo export APP_EXTERNAL_WEBADDRESS=https://\${DOCKERHOST}:\${PROXY_HTTPS_PORT} >> scratch/$version/$environment/additional.env
	echo export RAILS_ENV=production >> scratch/$version/$environment/additional.env
	chmod +x scratch/$version/$environment/additional.env
	cp proxy.env scratch/$version/$environment/

	echo "# Passwords and other secure information for Revenue Scotland" > scratch/$version/$environment/password.env
	echo FL_ENDPOINT_ROOT='http://lg-axway-qa.development.local:21080/communication' >> scratch/$version/$environment/password.env
	echo FL_USERNAME='EXTPWSUSER' >> scratch/$version/$environment/password.env
	echo FL_PASSWORD='WN1cXnWarb@BIDp' >> scratch/$version/$environment/password.env

	echo ADDRESS_SEARCH_ENDPOINT='https://adr.necsws.com/nadrcommunication' >> scratch/$version/$environment/password.env
	echo ADDRESS_SEARCH_UID='NADRINT@REVSCOT' >> scratch/$version/$environment/password.env
	echo ADDRESS_SEARCH_PWD='N0RTHGATE' >> scratch/$version/$environment/password.env
	echo ADDRESS_SEARCH_PROXY='http://10.102.160.19:8080' >> scratch/$version/$environment/password.env

	echo COMPANY_SEARCH_ENDPOINT='https://api.companieshouse.gov.uk' >> scratch/$version/$environment/password.env
	echo COMPANY_SEARCH_UID='OF_NbbTBvNjzR8TvcfgjSPlpDs4PdHJx_JO-H7Ib' >> scratch/$version/$environment/password.env
	echo COMPANY_SEARCH_PWD='' >> scratch/$version/$environment/password.env
	
	echo REDIS_PASS=${REDIS_PASS} >> scratch/$version/$environment/password.env
	echo REDIS_CACHE_URL="redis://:${REDIS_PASS_URI}@revscot-redis-${environment}:6379/1" >> scratch/$version/$environment/password.env

	exit 0
else
	echo -e "Usage: $0 version environment dockerImageName"
	echo -e "\tversion\tnumber must be of the form x.y.build"
	echo -e "\tenvironment\tthe name of the environment"
	echo -e "\tdockerImageName\tthe 'root' name of the docker image, i.e. without esb or ui suffix"
	exit 1
fi
