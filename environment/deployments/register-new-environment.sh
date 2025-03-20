#!/bin/bash
now=$(date -R)
set -x
curl -X PUT \
	https://lg-core-rel01.development.local:443/api/environment \
	-d "{\"appId\":\"$1\",\"testType\":\"$2\",\"version\":\"$3\",\"created\":\"$now\",\"host\":\"$4\",\"url\":\"$5\",\"label\":\"$6\",\"comment\":\"$7\"}"
