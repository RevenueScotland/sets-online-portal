#!/bin/bash

cert_folder=$1

DOMAIN=$(hostname)
export PASSPHRASE=$2
export CA_PASSPHRASE=$2
export CLEANUP=${3-1}
export RANDFILE=.rnd

if [ -z "${OPENSSL_CONF}" ]; then
    export OPENSSL_CONF=$(pwd)/openssl.cnf
fi    
export CN=$DOMAIN

if [ -z "${EXTERNAL_HOST}" ]; then
    export EXTERNAL_HOST=${DOMAIN}
fi

function addAdditionalSubjects {
    local IFS=","
    local TMPDIR=/var/tmp/ndsuser
    read -ra SUBJ <<< "$ADDITIONAL_SUBJECTS"
    local index=3
    local ip_index=1
    for i in "${SUBJ[@]}"; do
        local prefix=${i%%:*}
        local hostip=${i##*:}
        if [ "${prefix}" == "IP" ] ; then
                echo "IP."$ip_index "=" $hostip >> $OPENSSL_CONF
                ((ip_index+=1))
        else
                echo "DNS."$index "=" $hostip >> $OPENSSL_CONF
                ((index+=1))
        fi
    done
}

# if there isn't a CA cert in the folder create it
if [ ! -f $1/ca-truststore.p12 ]; then
    echo Generating new CA certificate
	openssl genrsa -aes256 -out $1/ca-key.pem -passout env:CA_PASSPHRASE 4096
	openssl req -new -x509 -days 3650 -batch -key $1/ca-key.pem -passin env:CA_PASSPHRASE -sha256 -out $1/ca-cert.pem -extensions v3_ca
	cat $1/ca-key.pem $1/ca-cert.pem > $1/ca-key-cert.pem
	openssl pkcs12 -export -passin env:CA_PASSPHRASE -in $1/ca-key-cert.pem -passout env:CA_PASSPHRASE -out $1/ca-truststore.p12 -name tomcat-ssl -CAfile $1/ca-cert.pem -caname root -chain
else
    echo Using existing CA certificate
	source $1/passphrase.txt
    echo export TRUSTSTORE_PASSWORD=$CA_PASSPHRASE > /var/tmp/truststore_password.txt
    chmod +x /var/tmp/truststore_password.txt
    rm -rf $1/passphrase.txt
fi

# if there are no certs already in the folder create them
if [ ! -f $1/server-keystore.p12 ]; then

    # are there any ADDITIONAL_SUBJECTS, if so add them to the end of the openssl configuration file
    if [ ! -z "$ADDITIONAL_SUBJECTS" ]; then
        addAdditionalSubjects
    fi

    echo Generating new Server certificate
	openssl genrsa -aes256 -out $1/server-key.pem -passout env:PASSPHRASE 4096
	openssl req -sha256 -subj "/CN=${EXTERNAL_HOST}" -batch -new -key $1/server-key.pem -passin env:PASSPHRASE -out $1/server.csr -config $OPENSSL_CONF
	openssl x509 -req -days 3650 -sha256 -in $1/server.csr -CA $1/ca-cert.pem -passin env:CA_PASSPHRASE -CAkey $1/ca-key.pem -CAcreateserial -CAserial ./serial -out $1/server-cert.pem  -extensions v3_req -extfile $OPENSSL_CONF
	cat $1/server-key.pem $1/server-cert.pem > $1/server-key-cert.pem
	openssl pkcs12 -export -passin env:PASSPHRASE -in $1/server-key-cert.pem -passout env:PASSPHRASE -out $1/server-keystore.p12 -name tomcat-ssl -CAfile $1/ca-cert.pem -caname root -chain

fi

[ -x "$SETCERT_PRECLEANUP_HOOK" ] && $SETCERT_PRECLEANUP_HOOK $cert_folder $CA_PASSPHRASE $CLEANUP

# Delete an CA files that aren't required
[ $CLEANUP -eq 1 ] && rm -rf $1/ca-key.pem $1/ca-cert.pem
[ $CLEANUP -eq 1 ] && rm -rf $1/server-key.pem $1/server.csr $1/server-cert.pem

openssl rsa -in $1/server-key.pem -passin env:PASSPHRASE  -out $1/server-key-nopass.pem

rm -f $1/*.p12 $1/*.csr $1/ca-key-cert.pem  $1/ca-key.pem $1/server-key-cert.pem $1/server-key.pem

