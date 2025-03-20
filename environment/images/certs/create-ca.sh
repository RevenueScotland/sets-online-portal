#!/bin/bash

host=$1

baseDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -f ${baseDir}/ca/${host}/ca-truststore.p12 ]; then

	folder=${baseDir}/ca/${host}
	mkdir -p ${folder}

	export PASSPHRASE=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 16)
	export OPENSSL_CONF=$(pwd)/openssl.cnf
	export CN=${host}

	echo CA_PASSPHRASE=${PASSPHRASE} > ${folder}/passphrase.txt
    chmod +x ${folder}/passphrase.txt
	openssl genrsa -aes256 -out ${folder}/ca-key.pem -passout env:PASSPHRASE 4096
	openssl req -new -x509 -days 3650 -batch -key ${folder}/ca-key.pem -passin env:PASSPHRASE -sha256 -out ${folder}/ca-cert.pem -extensions v3_ca
	cat ${folder}/ca-key.pem ${folder}/ca-cert.pem > ${folder}/ca-key-cert.pem
	openssl pkcs12 -export -passin env:PASSPHRASE -in ${folder}/ca-key-cert.pem -passout env:PASSPHRASE -out ${folder}/ca-truststore.p12 -name tomcat-ssl -CAfile ${folder}/ca-cert.pem -caname root -chain
fi
