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
CAVPNNAME="CaVpn.${SUFFIXDNS}"
CERTVPNNAME="Cert1Vpn.${SUFFIXDNS}"
VPNCACHAIN="CaVpnChain.pem"

CAROOTPWD="eole21"
CAVPNPWD="eole21"
CERTVPNPWD="eole"
P12VPNPWD="eole21"

# Génération CA ROOT
echo "Personnalisation ${CONFFILE} pour ${CAROOTNAME}"
cp "${CONFFILE}" "${CONFFILE}.orig"
sed -i "s,@@HOME@@,$HOME,g" "${CONFFILE}"
sed -i "s,@@SSLDIR@@,$CERTDIR,g" "${CONFFILE}"
sed -i "s,@@ISSUER_CN@@,$CAROOTNAME,g" "${CONFFILE}"
sed -i "s,@@CN-CERT@@,$CAROOTNAME,g" "${CONFFILE}"
sed -i "s,@@PASSWD@@,$CAROOTPWD,g" "${CONFFILE}"
echo "Génération ${CAROOTNAME}"
openssl req -x509 -config "${CONFFILE}" -newkey rsa:2048 -days 1825 -keyout ${CERTDIR}/private/${CAROOTNAME}.key -out ${CERTDIR}/certs/${CAROOTNAME}.pem -extensions ac-ext
# Génération CRL de CA ROOT
echo "Génération CRL pour ${CAROOTNAME}"
openssl ca -gencrl -config "${CONFFILE}" -crldays 30 -passin pass:"${CAROOTPWD}" -out ${CERTDIR}/crls/${CAROOTNAME}.crl
mv "${CONFFILE}.orig" "${CONFFILE}"

# Génération CA VPN
echo "Personnalisation ${CONFFILE} pour ${CAVPNNAME}"
cp "${CONFFILE}" "${CONFFILE}.orig"
sed -i "s,@@HOME@@,$HOME,g" "${CONFFILE}"
sed -i "s,@@SSLDIR@@,$CERTDIR,g" "${CONFFILE}"
sed -i "s,@@ISSUER_CN@@,$CAROOTNAME,g" "${CONFFILE}"
sed -i "s,@@CN-CERT@@,$CAVPNNAME,g" "${CONFFILE}"
sed -i "s,@@PASSWD@@,$CAVPNPWD,g" "${CONFFILE}"
echo "Génération requête pour ${CAVPNNAME}"
openssl req -new -newkey rsa:2048 -days 1825 -config "${CONFFILE}" -keyout ${CERTDIR}/private/${CAVPNNAME}.key -out ${CERTDIR}/certs/${CAVPNNAME}.p10
echo "Signature ${CAVPNNAME} par ${CAROOTNAME}"
openssl ca -in ${CERTDIR}/certs/${CAVPNNAME}.p10 -config "${CONFFILE}" -passin pass:"${CAROOTPWD}" -out ${CERTDIR}/certs/${CAVPNNAME}.pem -batch -notext -extensions ac-ext
# Génération CRL de CA VPN
echo "Génération CRL pour ${CAVPNNAME}"
openssl ca -gencrl -config "${CONFFILE}" -crldays 30 -passin pass:"${CAVPNPWD}" -out ${CERTDIR}/crls/${CAVPNNAME}.crl
mv "${CONFFILE}.orig" "${CONFFILE}"

# Génération certificat final VPN
echo "Personnalisation ${CONFFILE} pour ${CERTVPNNAME}"
cp "${CONFFILE}" "${CONFFILE}.orig"
sed -i "s,@@HOME@@,$HOME,g" "${CONFFILE}"
sed -i "s,@@SSLDIR@@,$CERTDIR,g" "${CONFFILE}"
sed -i "s,@@ISSUER_CN@@,$CAVPNNAME,g" "${CONFFILE}"
sed -i "s,@@CN-CERT@@,$CERTVPNNAME,g" "${CONFFILE}"
sed -i "s,@@PASSWD@@,$CERTVPNPWD,g" "${CONFFILE}"
echo "Génération requête pour ${CERTVPNNAME}"
openssl req -new -newkey rsa:2048 -days 1825 -config "${CONFFILE}" -keyout ${CERTDIR}/private/${CERTVPNNAME}.key -out ${CERTDIR}/certs/${CERTVPNNAME}.p10
echo "Signature ${CERTVPNNAME} par ${CAVPNNAME}"
openssl ca -in ${CERTDIR}/certs/${CERTVPNNAME}.p10 -config "${CONFFILE}" -passin pass:"${CAVPNPWD}" -out ${CERTDIR}/certs/${CERTVPNNAME}.pem -batch -notext -extensions serv-ext
mv "${CONFFILE}.orig" "${CONFFILE}"

# Génération fichier PKCS12
echo "Génération du fichier au format PKCS12 : ${CERTVPNNAME}.p12"
cat ${CERTDIR}/certs/${CAROOTNAME}.pem ${CERTDIR}/certs/${CAVPNNAME}.pem > ${CERTDIR}/certs/$VPNCACHAIN
openssl pkcs12 -export -in ${CERTDIR}/certs/${CERTVPNNAME}.pem -inkey ${CERTDIR}/private/${CERTVPNNAME}.key -certfile ${CERTDIR}/certs/$VPNCACHAIN -passin pass:"${CERTVPNPWD}" -passout pass:"${P12VPNPWD}" -out ${CERTDIR}/certs/${CERTVPNNAME}.p12
