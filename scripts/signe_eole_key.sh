#!/bin/bash -x

openssl x509 -noout -subject -in /etc/ssl/req/eole.p10 
openssl x509 -noout -issuer -in /etc/ssl/req/eole.p10 
  
echo "  Signature du certificat pour le CA"
echo -e "eole21\\ny\\ny\\n" |\
openssl ca \
      -config /mnt/eole-ci-tests/security/pki/config/ACEoleCI.config \
      -policy policy_anything \
      -passin stdin \
      -out /etc/ssl/req/eoleSigned.crt \
      -infiles /etc/ssl/req/eole.p10 
      
#-purpose sslserver 
openssl verify \
        -verbose \
        -CAfile /mnt/eole-ci-tests/security/pki/certificats/ACEoleCI.crt \
        /etc/ssl/req/eoleSigned.crt

openssl x509 -noout -subject -in /etc/ssl/req/eoleSigned.crt 
openssl x509 -noout -issuer -in /etc/ssl/req/eoleSigned.crt
openssl x509 -noout -purpose -in /etc/ssl/req/eoleSigned.crt 

cat /etc/ssl/certs/eole.key /etc/ssl/req/eoleSigned.crt >/usr/local/share/ca-certificates/eole.crt
rm /etc/ssl/req/eoleSigned.crt
update-ca-certificates
cp /etc/ssl/certs/eole.pem /etc/ssl/certs/eole.crt        