#!/bin/bash

# Starts a docker-compose application given the version number, environment and dockerImageName which
# are all supplied on the command line. This first allocates unique ports for each of the exposed
# ports (so multiple instances can run at once, but the port numbers are fixed, and can be published)
# then pulls the latest images from our docker registry, and then starts the application.

# Use DOCKER_REG and/or DOCKER_RELEASE_REG environment variables to override NDS docker registry

set -e

docker_reg=${DOCKER_REG:-${REGISTRY:-lg-bld-cont01.development.local:8443}}
release_docker_reg=${DOCKER_RELEASE_REG:-lg-bld-cont01.development.local:8443}

progName=$(basename $0)
version=$1
image_version=${version}
altVersion=${1//./-}
environment=$2
dockerImageName=$3
releaseVersion=$4
runUser=${5:-ndsuser}
projectName=${dockerImageName}${version//./}${environment}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

BRANCH=develop
TAG=${image_version}_${BRANCH}

function replace_in_compose
{
	file=$1
	
	if [[ -f "${file}" ]]; then 
		sed -i 's/${VERSION}/'${version}'/g;s/${ALTVERSION}/'$altVersion'/g;s/${ENVIRONMENT}/'${environment}'/g;s/${DOCKERIMAGENAME}/'$dockerImageName'/g' ${file}
	fi
}

function create_volumes
{
        file=$1

        if [[ -f "${file}" ]]; then
                # remove any existing, and create any exposed volumes - docker doesn't autocreate these when the :Z option is used. Set them all to be owned by ${runUser}
                grep -Po "^\s*-\s+\K([^:]*)/:[^:]*/:Z$" ${file} | cut -d : -f 1 | envsubst | xargs ${DIR}/file-filter.sh | xargs -r sudo rm -rf
                # create any shares
                grep -Po "^\s*-\s+\K([^:]*)/:[^:]*/:Z$" ${file} | cut -d : -f 1 | envsubst | xargs ${DIR}/file-filter.sh | xargs -r sudo mkdir -p
                grep -Po "^\s*-\s+\K([^:]*)/:[^:]*/:Z$" ${file} | cut -d : -f 1 | envsubst | xargs ${DIR}/file-filter.sh | xargs -r sudo chown -R ${runUser}:${runUser}
        fi
}

function remove_existing
{
	file=$1

	if [[ -f "${file}" ]]; then 
		grep -Po "container_name:\s*\K(.*)" ${file} | xargs -I {} bash -c 'docker rm -f {} &> /dev/null || true'
	fi
}

if [[ -n "${version}" ]] && [[ -n "${environment}" ]]  && [[ -n "${dockerImageName}" ]]; then
	echo "Running application ${dockerImageName} version ${version} for environment ${environment}"
	mkdir -p scratch/${version}/${environment}
   
	echo "# Passwords for ${dockerImageName}" > scratch/${version}/${environment}/password.env
 	echo "# Properties for "${dockerImageName}" version "${version}" for the "${environment}" environment" > scratch/${version}/${environment}/env.properties
	echo "APP_HOST="$(hostname -f) >> scratch/${version}/${environment}/env.properties

	[ -x $PWD/app-config.${environment}.sh ] && $PWD/./app-config.${environment}.sh ${version} ${environment} ${dockerImageName} ${dockerImageName}/${version}/${environment} ${releaseVersion}
	export DOCKERHOST=$(hostname -f)
	export VERSION=${version}
	export IMAGE_VERSION=$image_version
	export ALTVERSION=$altVersion
	export ENVIRONMENT=${environment}
	export DOCKERIMAGENAME=$dockerImageName
	export HOSTNAME=$(hostname)
	export VOLUME_PATH=${DOCKERIMAGENAME}/${VERSION}/${ENVIRONMENT}
	export RELEASE_VERSION=$image_version
	export PROJECT_NAME=$projectName
	[ -f scratch/${version}/${environment}/env.properties ] && export $(cat scratch/${version}/${environment}/env.properties | envsubst | grep -v ^# | xargs)
    [ -x scratch/${version}/${environment}/additional.env ] && export $(cat scratch/${version}/${environment}/additional.env | envsubst | grep -v ^# | xargs)
 
	cp docker-compose.yml scratch/${version}/${environment}/docker-compose.yml
	if [ -f docker-compose.extend.${ENVIRONMENT}.yml ]; then 
		cp docker-compose.extend.${ENVIRONMENT}.yml scratch/${version}/${environment}/docker-compose.extend.${ENVIRONMENT}.yml
		extra_compose="-f docker-compose.extend.${ENVIRONMENT}.yml"
	else
		extra_compose=""
	fi

        pushd scratch/${version}/${environment} &> /dev/null

	replace_in_compose "docker-compose.yml"
	replace_in_compose "docker-compose.extend.${ENVIRONMENT}.yml"

	if [[ -n "${releaseVersion}" ]]; then
		docker_reg=${release_docker_reg}
        if [[ "${dockerImageName}" == "revscot" ]]; then
            TAG=${TAG}-${dockerImageName}-${releaseVersion}
        else
            TAG=${TAG}-${dockerImageName:3:12}-${releaseVersion}
        fi
	fi
    
	remove_existing "docker-compose.yml"
	remove_existing "docker-compose.extend.${ENVIRONMENT}.yml"

	create_volumes "docker-compose.yml"
	create_volumes "docker-compose.extend.${ENVIRONMENT}.yml"

	echo Passw0rd | docker login --username jenkins --password-stdin ${docker_reg} &> /dev/null
	COMPOSE_TLS_VERSION=TLSv1_2 COMPOSE_HTTP_TIMEOUT=360 REGISTRY=${docker_reg} TAG=${TAG} BRANCH=${BRANCH}\
		docker-compose --ansi never --project-name ${projectName} -f docker-compose.yml ${extra_compose} up -d --no-color --quiet-pull

	[ -f additional.env ] && cat additional.env >> env.properties
	cat password.env >> env.properties
	popd &> /dev/null

	[ -x "$PWD/post-install.${environment}.sh" ] && $PWD/post-install.${environment}.sh ${version} ${environment} ${dockerImageName} ${dockerImageName}/${version}/${environment} ${releaseVersion}
	[ -x "$PWD/post-install.sh" ] && $PWD/post-install.sh ${version} ${environment} ${dockerImageName} ${dockerImageName}/${version}/${environment} ${releaseVersion}

	exit 0
else
	echo -e "Usage: $0 version environment dockerImageName"
	echo -e "\tversion\tnumber must be of the form x.y.build"
	echo -e "\tenvironment\tthe name of the environment"
	echo -e "\tdockerImageName\tthe 'root' name of the docker image, i.e. without esb or ui suffix"
	exit 1
fi

