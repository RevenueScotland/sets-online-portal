#!/bin/bash

host=$1

baseDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -f ${baseDir}/client/${host}/client-truststore.p12 ]; then

    if [ ! -f ${baseDir}/ca/${host}/ca-truststore.p12 ]; then
        echo "Unable to locate CA certificates for host " $host
        exit 1
    fi

	folder=${baseDir}/client/${host}
    ca_folder=${baseDir}/ca/${host}
	mkdir -p ${folder}

	export PASSPHRASE=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 16)
	export OPENSSL_CONF=$(pwd)/openssl.cnf
	export CN=${host}
	source ${baseDir}/ca/${host}/passphrase.txt

	echo CLIENT_PASSPHRASE=${PASSPHRASE} > ${folder}/passphrase.txt
	chmod +x ${folder}/passphrase.txt
	openssl genrsa -aes256 -out ${folder}/client-key.pem -passout env:PASSPHRASE 4096
	openssl req -subj "/CN=${host}" -new -key ${folder}/client-key.pem -passin env:PASSPHRASE -out ${folder}/client.csr

	cat > ${folder}/extfile.cnf <<'EOF'
basicConstraints = CA:FALSE
nsCertType = client
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF

	openssl x509 -req -days 3650 -sha256 -in ${folder}/client.csr -CA ${ca_folder}/ca-cert.pem -passin pass:${CA_PASSPHRASE} -CAkey ${ca_folder}/ca-key.pem -CAcreateserial -out ${folder}/client-cert.pem -extfile ${folder}/extfile.cnf
	cat ${folder}/client-key.pem ${folder}/client-cert.pem > ${folder}/client-key-cert.pem
	openssl pkcs12 -export -passin env:PASSPHRASE -in ${folder}/client-key-cert.pem -passout env:PASSPHRASE -out ${folder}/client-keystore.p12 -name client-ssl -CAfile ${ca_folder}/ca-cert.pem -chain -caname root
	rm -rf ${folder}/extfile.cnf ${folder}/client.csr
fi
