#!/bin/bash
#!/bin/bash
echo Checking connection to https://localhost:${HTTPS_PORT}/
curl -s -S --connect-timeout 5 --max-time 20 --fail -k https://localhost:${HTTPS_PORT}/${APPLICATION_DOCROOT} >/dev/null || exit 1

