#!/bin/bash
container_name=$1
app_name=$2
new_version=$3
commit_prefix=$4
if [ -z "${container_name}" ] || [ -z "${app_name}" ] || [  -z "${new_version}" ] || [ -z "${commit_prefix}" ] ; then
  echo Get git commit history between a currently running container and a specified version
  echo $0 container_name app_name new_version git_prefix
  echo for example: $0 esb--man publicengagement 0.0.2124 PE
  exit 1
fi


if [[ $(sudo -E docker ps -qfname="${container_name}") ]]; then 
	echo Found container with partial name ${container_name} - assuming first parameter is a container name
	start_version=$(sudo -E docker inspect -f="{{ index .Config.Labels \"com.northgateps.nds.version\"}}" $(sudo -E docker ps -qf name="${container_name}") 2>/dev/null)
else 
	echo Can not find container with partial name ${container_name} - assuming it''s a version number
	start_version=${container_name}
fi

if [ -z "${start_version}" ] ; then
  echo ERROR: There is no environment running for ${app_name}, unable to get history
  exit 1
fi

if [[ ${start_version} == *.* ]]; then 
  start_commit=$(git log refs/tags/release/${app_name}/${start_version} -n 1 --pretty=format:%H 2>/dev/null)
else 
  start_commit=$(git log refs/tags/rc/${app_name}/${start_version} -n 1 --pretty=format:%H 2>/dev/null) 
fi

if [ -z "${start_commit}" ] ; then
  echo ERROR: Unable to get commit of release candidate branch creation for ${start_version} of ${app_name}
  exit 1
fi

if [ "${new_version}" == "latest" ]; then
        end_commit=$(git rev-parse HEAD 2>/dev/null)
else
        if [[ ${new_version} == *.* ]]; then
                end_commit=$(git log refs/tags/release/${app_name}/${new_version} -n 1 --pretty=format:%H 2>/dev/null)
        else
                end_commit=$(git log refs/tags/rc/${app_name}/${new_version} -n 1 --pretty=format:%H 2>/dev/null)
        fi
fi

echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ START OF NOTES ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
git --no-pager log --pretty=format:"%ai %an %s" --perl-regexp --author='^((?!jenkins).*)$' --no-merges --grep="(develop #${commit_prefix}-|#${commit_prefix}-|develop #NDS-|#NDS-)" ${start_commit}..${end_commit}
echo
echo +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ END OF NOTES +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

