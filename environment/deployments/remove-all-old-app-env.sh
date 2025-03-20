#!/bin/bash

# removes any stopped application suites of images for the supplied dockerImageName and
# environment EXCEPT for any that have the supplied version number - which are all supplied
# on the command line. 

# Log/data files are not cleared up

progName=$(basename $0)
version=$1
environment=$2
dockerImageName=$3

if [[ -n "${version}" ]] && [[ -n "${environment}" ]]  && [[ -n "${dockerImageName}" ]]; then
	echo "Removing any stopped application ${dockerImageName} (except version ${version}) for environment ${environment}"
	docker ps -a --no-trunc --filter="name=${dockerImageName}" --filter="status=exited" |
		grep ${environment} |
		grep -v ${version} |
		awk '{print $12}' |
		xargs echo Removing
        docker ps -a --no-trunc --filter="name=${dockerImageName}" --filter="status=exited" |
		grep ${environment} |
		grep -v ${version} |
		awk '{print $1}' |
		xargs -r docker rm -f
	docker network prune -f		
	exit 0
else
	echo -e "Usage: $0 version environment dockerImageName"
	echo -e "\tversion\tnumber must be of the form x.y.build - this will be kept running, all others stopped"
	echo -e "\tenvironment\tthe name of the environment"
	echo -e "\tdockerImageName\tthe 'root' name of the docker image, i.e. without esb or ui suffix"
	exit 1
fi
