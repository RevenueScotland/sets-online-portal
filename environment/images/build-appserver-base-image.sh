#!/bin/bash

# builds a base podman image for a standard NDS app server - without reference to any environment, so
# that other podman images (created by build-ldap-env-image), can extend this one. This creates
# an image, based on the Dockerfile. The created image is then stored in the podman registry, and 
# remove from this machine to save space.

set -e

# Use DOCKER_REG and/or DOCKER_RELEASE_REG environment variables to override NDS podman registry

docker_reg=${DOCKER_REG:-${REGISTRY:-lg-bld-cont01.development.local:8443}}
release_docker_reg=${DOCKER_RELEASE_REG:-lg-bld-cont01.development.local:8443}
src_docker_reg=${SRC_DOCKER_REG:-${SRC_REGISTRY:-${docker_reg:-lg-bld-cont01.development.local:8443}}}
src_release_docker_reg=${SRC_DOCKER_RELEASE_REG:-${release_docker_reg:-lg-bld-cont01.development.local:8443}}

progName=$(basename $0)
version=$1
appName=$2
appType=$3
releaseVersion=$4
releaseApplication=$5

dockerImageName=$(echo ${appName,,})
releaseTag=${releaseApplication:3:12}-${releaseVersion}

# build tags
TAG=develop
REGISTRY=${docker_reg}
SRCREGISTRY=${src_docker_reg}
DATETIME=$(date -Is)

if [[ -n "${version}" ]] && [[ -n "${appName}" ]]; then
	echo "Building podman image for ${appName} version ${version}"
	mkdir -p scratch/cacerts
	cp -f ../certs/ca/$(hostname)/* scratch/cacerts
	cp -Rf ../common/container/crs/ scratch

	if [[ -d "../common/container/"${appType} ]]; then
		cp -Rf ../common/container/${appType} scratch/${appType}
	fi
       
	if [[ -n "${releaseVersion}" ]]; then
		TAG=${TAG}-${releaseTag}
		REGISTRY=${release_docker_reg}
        SRCREGISTRY=${src_release_docker_reg}
		echo "Building for release ${releaseVersion}, using tag ${TAG}"
	fi

	if [[ -x "pre-build-step.sh" ]]; then
		echo "Executing Additional Pre Build Step: pre-build-step.sh"
		./pre-build-step.sh ${version} ${appName} ${releaseVersion} ${releaseApplication}
	fi

	newTag=${version}_${TAG}

    echo Passw0rd | podman login --username jenkins --password-stdin ${SRCREGISTRY} &> /dev/null
	echo Passw0rd| podman login --username jenkins --password-stdin ${REGISTRY} &> /dev/null
	podman build --squash-all --quiet --build-arg VERSION=${version} --build-arg REGISTRY=${SRCREGISTRY} --build-arg=TAG=${TAG} --build-arg DATETIME=${DATETIME} --pull=true --rm=true -t ${dockerImageName}:${newTag} . >/dev/null
	podman tag ${dockerImageName}:${newTag} ${REGISTRY}/${dockerImageName}:${newTag} &> /dev/null
	podman push ${REGISTRY}/${dockerImageName}:${newTag} &> /dev/null
	podman rmi -f ${REGISTRY}/${dockerImageName}:${newTag} ${dockerImageName}:${newTag} &>/dev/null || echo "${progName}: WARNING: $LINENO: Failed to remove podman image(s)"

	exit 0
else
	echo -e "Usage: $0 version appName"
	echo -e "\tversion\tnumber must be of the form x.y.build"
	echo -e "\tappName\tthe name of the application; the podman image will be a lowercase version of this"
	echo -e ""
	echo -e "Note: podman image names can only contain letters and numbers, and this script will fail if the appName contain other characters"
	exit 1
fi
