#!/bin/bash

importCertificatSSL()
{
  HOST_REMOTE="$1"
  PORT_REMOTE="$2"
  TITRE="$3"
  echo "importCertificatSSL ${HOST_REMOTE}:${PORT_REMOTE} ${TITRE}"
  echo "x" | timeout 1 openssl s_client -servername "${HOST_REMOTE}" -connect "${HOST_REMOTE}:${PORT_REMOTE}" -showcerts 2>/tmp/showcerts.err >/tmp/showcerts
  cdu=$?
  if [ "$cdu" == "0" ]
  then
    sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' </tmp/showcerts >"/tmp/certs.pem"
    ISSUER=$(openssl x509 -in /tmp/certs.pem -issuer -noout |sed 's/.* //')
    SUBJECT=$(openssl x509 -in /tmp/certs.pem -subject -noout |sed 's/.* //')
    TROUVE="0"
    find /tmp/import-certs/ -name *.pem | while read -r F 
    do
        if ! diff /tmp/certs.pem "$F" >/dev/null
        then
            TROUVE="1"
        fi
    done
    if [ "$TROUVE" == "0" ]
    then
        cp /tmp/certs.pem /tmp/import-certs/$ISSUER.pem
        RESULT="1"
    fi
  fi
}

. /root/getVMContext.sh NO_DISPLAY

RESULT="0"
rm -rf /tmp/import-certs
mkdir -p /tmp/import-certs
importCertificatSSL "etb1.ac-test.fr" "443" HTTPS
importCertificatSSL "etb1.ac-test.fr" "636" LDAPS
importCertificatSSL "etb1.ac-test.fr" "4200" EAD2
importCertificatSSL "etb1.ac-test.fr" "8443" "8443"
#importCertificatSSL "etb1.ac-test.fr" "7080" ZEPHIR

importCertificatSSL "scribe.dompedago.etb1.lan" "25" SMTPS
importCertificatSSL "scribe.dompedago.etb1.lan" "143" HTTPS
importCertificatSSL "scribe.dompedago.etb1.lan" "443" HTTPS
importCertificatSSL "scribe.dompedago.etb1.lan" "636" LDAPS
importCertificatSSL "scribe.dompedago.etb1.lan" "993" "993"
importCertificatSSL "scribe.dompedago.etb1.lan" "995" IMAPS
importCertificatSSL "scribe.dompedago.etb1.lan" "143" POPS
importCertificatSSL "scribe.dompedago.etb1.lan" "4200" EAD2
importCertificatSSL "scribe.dompedago.etb1.lan" "8443" "8443"
importCertificatSSL "scribe.dompedago.etb1.lan" "7080" ZEPHIR

importCertificatSSL "scribe.etb1.lan" "8888" WSS2
importCertificatSSL "scribe.etb1.lan" "8787" WSS

ls -l /usr/local/share/ca-certificats

ls -l /tmp/import-certs

if [ "$RESULT" == "1" ]
then
    echo "do update ca"
    set -x
    find /tmp/import-certs/ -name *.pem | while read -r F 
    do
        CRT=$(basename $F .pem)
        echo $CRT
        #rm -f "/usr/local/share/ca-certificats/${CRT}.crt"
        #cp -v "$F" /usr/local/share/ca-certificats/${CRT}.crt
        
        #certificateFile="MyCa.cert.pem"
        #certificateName="MyCA Name" 
        #for certDB in $(find  ~/.mozilla* ~/.thunderbird -name "cert8.db")
        #do
        #    certDir=$(dirname ${certDB});
        #    #log "mozilla certificate" "install '${certificateName}' in ${certDir}"
        #    certutil -A -n "${certificateName}" -t "TCu,Cuw,Tuw" -i ${certificateFile} -d ${certDir}
        #done
        
        #certutil -A -n "Description Name" -t "CT,C,C" -d dbm:/home/<username>/.mozilla/firefox/<default folder>/ -i certificate.crt
        #certutil -A -n "Description Name" -t "CT,C,C" -d sql:/home/<username>/.mozilla/firefox/<default folder>/ -i certificate.crt
    done
    set +x
    update-ca-certificates --verbose
    echo $?
else    
    echo "pas d' update ca"
fi
exit 0
	
