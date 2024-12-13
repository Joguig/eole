#!/bin/bash

if [ "$(id -u)" != "0" ]; then
    echo "Lancer la commande en sudo ou avec l'utilisateur root"
    exit 1
fi

PKIDIR="/mnt/eole-ci-tests/security/certs"
CERTDIR="${PKIDIR}/p12"
rm -rf ${CERTDIR}
mkdir -p ${CERTDIR}/certs
mkdir -m 700 -p ${CERTDIR}/{crls,newcerts,private}
touch ${CERTDIR}/index.txt
echo 01 > ${CERTDIR}/serial

CONFDIR=$(dirname "$0" )

SUFFIXDNS="ac-test.fr"
CONFFILE="${CONFDIR}/eolepki.conf"
CAROOTNAME="CaRoot.${SUFFIXDNS}"
CASSLNAME="CaSsl.${SUFFIXDNS}"
CERTSSLNAME="Cert1Ssl.${SUFFIXDNS}"
SSLCACHAIN="CaSslChain.pem"

CAROOTPWD="eole21"
CASSLPWD="eole21"
CERTSSLPWD="eole"
P12SSLPWD="eole21"

# Génération CA SSL
echo "Personnalisation ${CONFFILE} pour ${CASSLNAME}"
cp "${CONFFILE}" "${CONFFILE}.orig"
sed -i "s,@@HOME@@,$HOME,g" "${CONFFILE}"
sed -i "s,@@SSLDIR@@,$CERTDIR,g" "${CONFFILE}"
sed -i "s,@@ISSUER_CN@@,$CAROOTNAME,g" "${CONFFILE}"
sed -i "s,@@CN-CERT@@,$CASSLNAME,g" "${CONFFILE}"
sed -i "s,@@PASSWD@@,$CASSLPWD,g" "${CONFFILE}"
echo "Génération requête pour ${CASSLNAME}"
openssl req -new -newkey rsa:2048 -days 1825 -config "${CONFFILE}" -keyout ${CERTDIR}/private/${CASSLNAME}.key -out ${CERTDIR}/certs/${CASSLNAME}.p10
echo "Signature ${CASSLNAME} par ${CAROOTNAME}"
openssl ca -in ${CERTDIR}/certs/${CASSLNAME}.p10 -config "${CONFFILE}" -passin pass:"${CAROOTPWD}" -out ${CERTDIR}/certs/${CASSLNAME}.pem -batch -notext -extensions ac-ext
# Génération CRL de CA SSL
echo "Génération CRL pour ${CASSLNAME}"
openssl ca -gencrl -config "${CONFFILE}" -crldays 30 -passin pass:"${CASSLPWD}" -out ${CERTDIR}/crls/${CASSLNAME}.crl
mv "${CONFFILE}.orig" "${CONFFILE}"

# Génération certificat final SSL
echo "Personnalisation ${CONFFILE} pour ${CERTSSLNAME}"
cp "${CONFFILE}" "${CONFFILE}.orig"
sed -i "s,@@HOME@@,$HOME,g" "${CONFFILE}"
sed -i "s,@@SSLDIR@@,$CERTDIR,g" "${CONFFILE}"
sed -i "s,@@ISSUER_CN@@,$CASSLNAME,g" "${CONFFILE}"
sed -i "s,@@CN-CERT@@,$CERTSSLNAME,g" "${CONFFILE}"
sed -i "s,@@PASSWD@@,$CERTSSLPWD,g" "${CONFFILE}"
echo "Génération requête pour ${CERTSSLNAME}"
openssl req -new -newkey rsa:2048 -days 1825 -config "${CONFFILE}" -keyout ${CERTDIR}/private/${CERTSSLNAME}.key -out ${CERTDIR}/certs/${CERTSSLNAME}.p10
echo "Signature ${CERTSSLNAME} par ${CASSLNAME}"
openssl ca -in ${CERTDIR}/certs/${CERTSSLNAME}.p10 -config "${CONFFILE}" -passin pass:"${CASSLPWD}" -out ${CERTDIR}/certs/${CERTSSLNAME}.pem -batch -notext -extensions serv-ext
mv "${CONFFILE}.orig" "${CONFFILE}"

# Génération fichier PKCS12
echo "Génération du fichier au format PKCS12 : ${CERTSSLNAME}.p12"
cat ${CERTDIR}/certs/${CAROOTNAME}.pem ${CERTDIR}/certs/${CASSLNAME}.pem > ${CERTDIR}/certs/$SSLCACHAIN
openssl pkcs12 -export -in ${CERTDIR}/certs/${CERTSSLNAME}.pem -inkey ${CERTDIR}/private/${CERTSSLNAME}.key -certfile ${CERTDIR}/certs/$SSLCACHAIN -passin pass:"${CERTSSLPWD}" -passout pass:"${P12SSLPWD}" -out ${CERTDIR}/certs/${CERTSSLNAME}.p12
