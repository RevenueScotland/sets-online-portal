#!/bin/bash

thisDir=$(dirname "$(readlink -f "$0")")
source ${thisDir}/environment.sh

mkdir -p ${FILE_UPLOAD_PATH} 

bundle exec puma -p 3000 -e ${RAILS_ENV}
