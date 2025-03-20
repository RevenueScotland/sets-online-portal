#!/bin/sh
exec curl --connect-timeout 5 --max-time 20 --silent --fail -k 0.0.0.0:3000/${APPLICATION_DOCROOT} > /dev/null || exit 1
