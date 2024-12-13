#!/bin/bash

if [ "$(id -u)" != "0" ]; then
    echo "Lancer la commande en sudo ou avec l'utilisateur root"
    exit 1
fi

CERTDIR="/tmp/p12"
rm -rf "${CERTDIR}"
mkdir -p "${CERTDIR}/certs"
mkdir -p "${CERTDIR}/crls"
chmod 700 "${CERTDIR}/crls"
mkdir -p "${CERTDIR}/newcerts"
chmod 700 "${CERTDIR}/newcerts"
mkdir -p "${CERTDIR}/private"
chmod 700 "${CERTDIR}/private"
touch "${CERTDIR}/index.txt"
echo 01 > "${CERTDIR}/serial"

CONFDIR=$(dirname "$0" )

SUFFIXDNS="ac-test.fr"
ORIG_CONFFILE="${CONFDIR}/eolepki.conf"
CONFFILE="${CERTDIR}/eolepki.conf"
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
cp "${ORIG_CONFFILE}" "${CONFFILE}"
sed -i "s,@@HOME@@,$HOME,g" "${CONFFILE}"
sed -i "s,@@SSLDIR@@,$CERTDIR,g" "${CONFFILE}"
sed -i "s,@@ISSUER_CN@@,$CAROOTNAME,g" "${CONFFILE}"
sed -i "s,@@CN-CERT@@,$CAROOTNAME,g" "${CONFFILE}"
sed -i "s,@@PASSWD@@,$CAROOTPWD,g" "${CONFFILE}"
sed -i "s,@@EXPIRATION_DAYS@@,2050,g" "${CONFFILE}"
sed -i "s,@@CA_EXPIRATION_DAYS@@,2050,g" "${CONFFILE}"
echo "Génération ${CAROOTNAME}"
openssl req -x509 -config "${CONFFILE}" -newkey rsa:2048 -days 2050 -keyout ${CERTDIR}/private/${CAROOTNAME}.key -out ${CERTDIR}/certs/${CAROOTNAME}.pem -extensions ac-ext
# Génération CRL de CA ROOT
echo "Génération CRL pour ${CAROOTNAME}"
openssl ca -gencrl -config "${CONFFILE}" -crldays 30 -passin pass:"${CAROOTPWD}" -out ${CERTDIR}/crls/${CAROOTNAME}.crl

# Génération CA VPN
echo "Personnalisation ${CONFFILE} pour ${CAVPNNAME}"
cp "${ORIG_CONFFILE}" "${CONFFILE}"
sed -i "s,@@HOME@@,$HOME,g" "${CONFFILE}"
sed -i "s,@@SSLDIR@@,$CERTDIR,g" "${CONFFILE}"
sed -i "s,@@ISSUER_CN@@,$CAROOTNAME,g" "${CONFFILE}"
sed -i "s,@@CN-CERT@@,$CAVPNNAME,g" "${CONFFILE}"
sed -i "s,@@PASSWD@@,$CAVPNPWD,g" "${CONFFILE}"
sed -i "s,@@CA_EXPIRATION_DAYS@@,2050,g" "${CONFFILE}"
sed -i "s,@@EXPIRATION_DAYS@@,2050,g" "${CONFFILE}"
echo "Génération requête pour ${CAVPNNAME}"
openssl req -new -newkey rsa:2048 -days 1825 -config "${CONFFILE}" -keyout ${CERTDIR}/private/${CAVPNNAME}.key -out ${CERTDIR}/certs/${CAVPNNAME}.p10
echo "Signature ${CAVPNNAME} par ${CAROOTNAME}"
openssl ca -in ${CERTDIR}/certs/${CAVPNNAME}.p10 -config "${CONFFILE}" -passin pass:"${CAROOTPWD}" -out ${CERTDIR}/certs/${CAVPNNAME}.pem -batch -notext -extensions ac-ext
# Génération CRL de CA VPN
echo "Génération CRL pour ${CAVPNNAME}"
openssl ca -gencrl -config "${CONFFILE}" -crldays 30 -passin pass:"${CAVPNPWD}" -out ${CERTDIR}/crls/${CAVPNNAME}.crl

# Génération certificat final VPN
echo "Personnalisation ${CONFFILE} pour ${CERTVPNNAME}"
cp "${ORIG_CONFFILE}" "${CONFFILE}"
sed -i "s,@@HOME@@,$HOME,g" "${CONFFILE}"
sed -i "s,@@SSLDIR@@,$CERTDIR,g" "${CONFFILE}"
sed -i "s,@@ISSUER_CN@@,$CAVPNNAME,g" "${CONFFILE}"
sed -i "s,@@CN-CERT@@,$CERTVPNNAME,g" "${CONFFILE}"
sed -i "s,@@PASSWD@@,$CERTVPNPWD,g" "${CONFFILE}"
sed -i "s,@@CA_EXPIRATION_DAYS@@,1825,g" "${CONFFILE}"
sed -i "s,@@EXPIRATION_DAYS@@,1825,g" "${CONFFILE}"
echo "Génération requête pour ${CERTVPNNAME}"
openssl req -new -newkey rsa:2048 -days 1825 -config "${CONFFILE}" -keyout ${CERTDIR}/private/${CERTVPNNAME}.key -out ${CERTDIR}/certs/${CERTVPNNAME}.p10
echo "Signature ${CERTVPNNAME} par ${CAVPNNAME}"
openssl ca -in ${CERTDIR}/certs/${CERTVPNNAME}.p10 -config "${CONFFILE}" -passin pass:"${CAVPNPWD}" -out ${CERTDIR}/certs/${CERTVPNNAME}.pem -batch -notext -extensions serv-ext

# Génération certificat final VPN pour test remplacement dans ARV
echo "Personnalisation ${CONFFILE} pour ${CERTVPNNAME}"
cp "${ORIG_CONFFILE}" "${CONFFILE}"
sed -i "s,@@HOME@@,$HOME,g" "${CONFFILE}"
sed -i "s,@@SSLDIR@@,$CERTDIR,g" "${CONFFILE}"
sed -i "s,@@ISSUER_CN@@,$CAVPNNAME,g" "${CONFFILE}"
sed -i "s,@@CN-CERT@@,$CERTVPNNAME,g" "${CONFFILE}"
sed -i "s,@@PASSWD@@,$CERTVPNPWD,g" "${CONFFILE}"
sed -i "s,@@CA_EXPIRATION_DAYS@@,2050,g" "${CONFFILE}"
sed -i "s,@@EXPIRATION_DAYS@@,2050,g" "${CONFFILE}"
echo "Génération requête pour ${CERTVPNNAME}"
openssl req -new -newkey rsa:2048 -days 2050 -config "${CONFFILE}" -keyout ${CERTDIR}/private/${CERTVPNNAME}-renew.key -out ${CERTDIR}/certs/${CERTVPNNAME}-renew.p10
echo "Signature ${CERTVPNNAME} par ${CAVPNNAME}"
openssl ca -in ${CERTDIR}/certs/${CERTVPNNAME}-renew.p10 -config "${CONFFILE}" -passin pass:"${CAVPNPWD}" -out ${CERTDIR}/certs/${CERTVPNNAME}-renew.pem -batch -notext -extensions serv-ext

# Génération fichier PKCS12 pour le premier certificat
echo "Génération du fichier au format PKCS12 : ${CERTVPNNAME}.p12"
cat ${CERTDIR}/certs/${CAROOTNAME}.pem ${CERTDIR}/certs/${CAVPNNAME}.pem > ${CERTDIR}/certs/$VPNCACHAIN
openssl pkcs12 -export -in ${CERTDIR}/certs/${CERTVPNNAME}.pem -inkey ${CERTDIR}/private/${CERTVPNNAME}.key -certfile ${CERTDIR}/certs/$VPNCACHAIN -passin pass:"${CERTVPNPWD}" -passout pass:"${P12VPNPWD}" -out ${CERTDIR}/certs/${CERTVPNNAME}.p12

# Génération fichier PKCS12 pour le deuxième certificat
echo "Génération du fichier au format PKCS12 : ${CERTVPNNAME}-renew.p12"
cat ${CERTDIR}/certs/${CAROOTNAME}.pem ${CERTDIR}/certs/${CAVPNNAME}.pem > ${CERTDIR}/certs/$VPNCACHAIN
openssl pkcs12 -export -in ${CERTDIR}/certs/${CERTVPNNAME}-renew.pem -inkey ${CERTDIR}/private/${CERTVPNNAME}-renew.key -certfile ${CERTDIR}/certs/$VPNCACHAIN -passin pass:"${CERTVPNPWD}" -passout pass:"${P12VPNPWD}" -out ${CERTDIR}/certs/${CERTVPNNAME}-renew.p12

# Génération fichier PKCS#7 pour la chaîne de certificats au format pem
openssl crl2pkcs7 -certfile ${CERTDIR}/certs/${CERTVPNNAME}.pem -nocrl -out ${CERTDIR}/certs/${CERTVPNNAME}_only.p7
# Génération fichier PKCS#7 pour la chaîne de certificats au format der
openssl crl2pkcs7 -certfile ${CERTDIR}/certs/${CERTVPNNAME}.pem -nocrl -outform der -out ${CERTDIR}/certs/${CERTVPNNAME}_only.p7b
# Génération fichier PKCS#7 pour le premier certificat au format pem
openssl crl2pkcs7 -certfile ${CERTDIR}/certs/${CAROOTNAME}.pem -certfile ${CERTDIR}/certs/${CAVPNNAME}.pem -certfile ${CERTDIR}/certs/${CERTVPNNAME}.pem -nocrl -out ${CERTDIR}/certs/${CERTVPNNAME}.p7
# Génération fichier PKCS#7 pour le premier certificat au format der
openssl crl2pkcs7 -certfile ${CERTDIR}/certs/${CAROOTNAME}.pem -certfile ${CERTDIR}/certs/${CAVPNNAME}.pem -certfile ${CERTDIR}/certs/${CERTVPNNAME}.pem -nocrl -outform der -out ${CERTDIR}/certs/${CERTVPNNAME}.p7b

chmod 644 ${CERTDIR}/certs/*
chmod 755 ${CERTDIR}/private
chmod 644 ${CERTDIR}/private/*
