#!/bin/bash

# Starts a docker-compose application given the version number, environment and dockerImageName which
# are all supplied on the command line. This first allocates unique ports for each of the exposed
# ports (so multiple instances can run at once, but the port numbers are fixed, and can be published)
# then pulls the latest images from our docker registry, and then starts the application.

# Use DOCKER_REG and/or DOCKER_RELEASE_REG environment variables to override NDS docker registry

docker_reg=${DOCKER_REG:-${REGISTRY:-lg-bld-cont01.development.local:8443}}
release_docker_reg=${DOCKER_RELEASE_REG:-lg-bld-cont01.development.local:8443}

progName=$(basename "$0")
version=""
image_version=$1
altVersion=""
environment=$2
dockerImageName=$3
releaseVersion=$4
runUser=${5:-ndsuser}
projectName=${dockerImageName}${version//./}${environment}

BRANCH=develop
TAG=${image_version}_${BRANCH}

function create_volumes
{
	file=$1

	if [[ -f "${file}" ]]; then 
        grep -Po "^\s*-\s+\K([^:]*)/:[^:]*/:Z$" ${file} | cut -d : -f 1 | envsubst | xargs -r sudo mkdir -p
        grep -Po "^\s*-\s+\K([^:]*)/:[^:]*/:Z$" ${file} | cut -d : -f 1 | envsubst | xargs -r sudo chown -R ${runUser}:${runUser}
	fi
}

function copy_local_volumes
{
	file=${1}
	
	if [[ -f "${file}" ]]; then
		grep -oP "^\s*-\s+\K(.{1,2}/[^:]+):[^:]+:Z" ${file} | cut -d : -f 1 | uniq | while read -r bind ; do
			tmpdir=$(sudo mktemp -d --tmpdir=${tmp_folder})
			pwd
			line="../../../${bind}"
			if [[ -d "${line}" ]] ; then 
				sudo cp -r ${line}/* ${tmpdir}
				sed -i "s~${bind}~${tmpdir}~g" ${file}
			else
				sudo cp ${line} ${tmpdir}/
				sed -i "s~${bind}~${tmpdir}/$(basename ${line})~g" ${file}
			fi
			sudo chown -R ${runUser}:${runUser} ${tmpdir}
			sudo chmod -R gu=rwX,o=rX ${tmpdir}
		done
	fi
}

if [[ -n "${image_version}" ]] && [[ -n "${environment}" ]]  && [[ -n "${dockerImageName}" ]]; then
        echo "Running application ${dockerImageName} version ${image_version} for environment ${environment}"
        mkdir -p scratch/${image_version}/${environment}

        [ -x "$PWD/app-config.${environment}.sh" ] && "$PWD/./app-config.${environment}.sh" ${image_version} ${environment} ${dockerImageName}

        echo '# Environment settings - source additional.env if present before sourcing this file' > scratch/${image_version}/${environment}/settings.env
        echo export DOCKERHOST=$(hostname -f) >> scratch/${image_version}/${environment}/settings.env
        echo export VERSION=${version} >> scratch/${image_version}/${environment}/settings.env
        echo export IMAGE_VERSION=${image_version} >> scratch/${image_version}/${environment}/settings.env
        echo export ALTVERSION=$altVersion >> scratch/${image_version}/${environment}/settings.env
        echo export ENVIRONMENT=${environment} >> scratch/${image_version}/${environment}/settings.env
        echo export DOCKERIMAGENAME=${dockerImageName} >> scratch/${image_version}/${environment}/settings.env
        echo export HOSTNAME=$(hostname) >> scratch/${image_version}/${environment}/settings.env
        echo export VOLUME_PATH=\${DOCKERIMAGENAME}/\${ENVIRONMENT} >> scratch/${image_version}/${environment}/settings.env
        echo export RELEASE_VERSION=${image_version} >> scratch/${image_version}/${environment}/settings.env
        echo export PROJECT_NAME=$projectName >> scratch/${image_version}/${environment}/settings.env

        chmod +x scratch/${image_version}/${environment}/settings.env
        source scratch/${image_version}/${environment}/settings.env
        [ -x scratch/${image_version}/${environment}/additional.env ] && source scratch/${image_version}/${environment}/additional.env
        [ -x scratch/${image_version}/${environment}/settings-override.env ] && source scratch/${image_version}/${environment}/settings-override.env

        sed 's/${VERSION}/'${VERSION}'/g;s/${ALTVERSION}/'${ALTVERSION}'/g;s/${ENVIRONMENT}/'${ENVIRONMENT}'/g;s/${DOCKERIMAGENAME}/'${DOCKERIMAGENAME}'/g;s/${DOCKERHOST}/'${DOCKERHOST}'/g' docker-compose.yml > scratch/${image_version}/${environment}/docker-compose.yml
        if [[ -n "$releaseVersion" ]]; then
                echo "Running release $releaseVersion"
                docker_reg=${release_docker_reg}
                if [[ "${dockerImageName}" == "revscot" ]]; then
                    TAG=${TAG}-${dockerImageName}-${releaseVersion}
                else
                    TAG=${TAG}-${dockerImageName:3:12}-${releaseVersion}
                fi
        fi

        if [ -f docker-compose.extend.${ENVIRONMENT}.yml ]; then 
            sed 's/${VERSION}/'${VERSION}'/g;s/${ALTVERSION}/'${ALTVERSION}'/g;s/${ENVIRONMENT}/'${ENVIRONMENT}'/g;s/${DOCKERIMAGENAME}/'${DOCKERIMAGENAME}'/g;s/${DOCKERHOST}/'${DOCKERHOST}'/g' docker-compose.extend.${ENVIRONMENT}.yml > scratch/${image_version}/${environment}/docker-compose.extend.${ENVIRONMENT}.yml
            extra_compose="-f docker-compose.extend.${ENVIRONMENT}.yml"
        else
            extra_compose=""
        fi

        pushd scratch/${image_version}/${environment} &> /dev/null
        # create any exposed volumes - docker doesn't autocreate these when the :Z option is used. Set them all to be owned by ${runUser}
        create_volumes "docker-compose.yml"
        create_volumes "docker-compose.extend.${ENVIRONMENT}.yml"
       
	# copy any local volumes (start with either ./ or ../ in the volumes section; the trailing / in the container bind mount should be missing also, otherwise the above will match it
	copy_local_volumes "docker-compose.yml"
	copy_local_volumes "docker-compose.extend.${ENVIRONMENT}.yml"
 
        if [ -d /data/${DOCKERIMAGENAME}/${environment} ] ; then
		# back up any previous data
        	echo Backing up existing data
	        sudo mkdir -p /data/backup/${dockerImageName}/
	        sudo tar --selinux -cpjf /data/backup/${dockerImageName}/${environment}-pre${image_version}-$(date +%Y%m%dT%H%m%S).tgz /data/${DOCKERIMAGENAME}/${environment} &> /dev/null
	        pushd /data/backup/${dockerImageName}/ > /dev/null
	        ls -tp | grep -v '/$' | tail -n +6 | tr '\n' '\0' | sudo xargs -r -0 rm --
	        popd &> /dev/null
	        echo Backup complete
	    fi

        echo Passw0rd | docker login --username jenkins --password-stdin ${docker_reg} &> /dev/null
        COMPOSE_TLS_VERSION=TLSv1_2 COMPOSE_HTTP_TIMEOUT=360 REGISTRY=${docker_reg} TAG=${TAG} BRANCH=${BRANCH}\
		    docker-compose --ansi never --project-name ${projectName} -f docker-compose.yml ${extra_compose} up -d --no-color --quiet-pull

        echo "# Properties for "${dockerImageName}" version "${image_version}" for the "${environment}" environment" > env.properties
        echo "APP_HOST="$(hostname -f) >> env.properties
        [ -f additional.env ] && sed 's/export //g;' additional.env >> env.properties
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

