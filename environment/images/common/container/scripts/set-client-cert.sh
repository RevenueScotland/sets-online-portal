#!/bin/bash

cert_folder=$1

DOMAIN=$(hostname)
export CA_PASSPHRASE=$2
export CLEANUP=${3-1}
export OPENSSL_CONF=$(pwd)/openssl.cnf
export CN=$DOMAIN
export RANDFILE=/var/tmp/ndsuser/.rnd

export CLIENT_KEYSTORE_PASSWORD=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 16)

openssl genrsa -aes256 -out $1/client-key.pem -passout env:CLIENT_KEYSTORE_PASSWORD 4096
openssl req -sha256 -subj "/CN=${NDS_CLIENT_NAME}" -batch -new -key $1/client-key.pem -passin env:CLIENT_KEYSTORE_PASSWORD -out $1/client.csr -config $OPENSSL_CONF
openssl x509 -req -days 3650 -sha256 -in $1/client.csr -CA $1/ca-cert.pem -passin env:CA_PASSPHRASE -CAkey $1/ca-key.pem -CAcreateserial -CAserial ./serial -out $1/client-cert.pem -extfile /var/tmp/cert/extfile.cnf

cat $1/client-key.pem $1/client-cert.pem > $1/client-key-cert.pem
openssl pkcs12 -export -passin env:CLIENT_KEYSTORE_PASSWORD -in $1/client-key-cert.pem -passout env:CLIENT_KEYSTORE_PASSWORD -out $1/client-keystore.p12 -name tomcat-ssl -CAfile $1/ca-cert.pem -caname root -chain

[ $CLEANUP -eq 1 ] && rm -rf $1/client-key.pem $1/client.csr $1/client-cert.pem

echo export CLIENT_KEYSTORE_PASSWORD=$CLIENT_KEYSTORE_PASSWORD > $(pwd)/password.txt

if [ -x "/var/tmp/ndsuser/copy-conf.sh" ] ; then 
    /var/tmp/ndsuser/copy-conf.sh
fi