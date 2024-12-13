#!/bin/bash
# shellcheck disable=SC2050

# root : ACEoleCi
# intermediaire : ACEoleCiSsl 
# intermediaire : ACEoleCiMail 
# intermediaire : ACEoleCiVpn 

password="eole21"
owner="ACEoleCI"
company=eole
unit=ci
email=
town=dijon
state=bourgogne
country=FR

EOLE_CI_TESTS_DIR=/mnt/eole-ci-tests
EOLE_CI_TESTS_CONFIGURATION="$EOLE_CI_TESTS_DIR/configuration"
EOLE_CI_TESTS_SECURITY="$EOLE_CI_TESTS_DIR/security"
[ ! -d "$EOLE_CI_TESTS_SECURITY" ] && mkdir "$EOLE_CI_TESTS_SECURITY"
pki_path="$EOLE_CI_TESTS_SECURITY/pki"

function myopenssl()
{
    #2>&1 | tee "$pki_path/genere.log"
    if openssl "$@"
    then
        exit 1
    fi 
}

function myopensslCommand()
{
    echo -n -e "$1" >$pki_path/openssl.command
    shift
    myopenssl genrsa \
            -passout stdin \
            -des3 \
            -out "$pki_path/certificats/ACEoleCI.pem" \
            1024 \
            <"$pki_path/openssl.command" 
    rm "$pki_path/openssl.command"
}

function resetCertificats()
{
    rm -rf "$pki_path"
    machines=$(ls "$EOLE_CI_TESTS_CONFIGURATION/")
    for machine in $machines  
    do
        repmachine="$EOLE_CI_TESTS_SECURITY/$machine" 
        echo "Clean $repmachine" 
        [ -f "$repmachine/serveur.key" ] && rm "$repmachine/serveur.key" 
        [ -f "$repmachine/serveur.crt" ] && rm "$repmachine/serveur.crt"
        [ -f "$repmachine/serveur.csr" ] && rm "$repmachine/serveur.csr"
        [ -f "$repmachine/serveur.pem" ] && rm "$repmachine/serveur.pem" 
        [ -f "$repmachine/serveur.p12" ] && rm "$repmachine/serveur.p12"
    done
}

echo "*****************************************************************"
echo "CA Root"
echo "*****************************************************************"
function checkCA()
{
    if [ ! -f "$pki_path/db/ca.db.serial" ]
    then
        echo "- Initialisation des numéros de séries à 1"
        echo "01" >"$pki_path/db/ca.db.serial"
    fi
    
    if [ ! -f "$pki_path/db/ca.db.index" ]
    then
        echo "- Initialisation de l'index des certificats"
        touch "$pki_path/db/ca.db.index"
    fi
    
    if [ ! -f $pki_path/db/ca.db.index.attr ]
    then
        echo "- Initialisation des attributs de l'index des certificats"
        # tres important car par defaut = yes !!
        echo "unique_subject=no" >"$pki_path/db/ca.db.index.attr"
    fi
    
    if [ ! -f "$pki_path/config/ACEoleCI.config" ]
    then
        echo "- Initialisation de l'index des certificats"
        cat >"$pki_path/config/ACEoleCI.config" <<END
[ ca ]
default_ca              = CA_EoleCI

[ CA_EoleCI ]
dir                     = $pki_path/db
certs                   = $pki_path/db
new_certs_dir           = $pki_path/db/ca.db.certs
database                = $pki_path/db/ca.db.index
serial                  = $pki_path/db/ca.db.serial
RANDFILE                = $pki_path/db/ca.db.rand
certificate             = $pki_path/certificats/ACEoleCI.crt
private_key             = $pki_path/certificats/ACEoleCI.pem
default_days            = 3000
default_crl_days        = 30
default_md              = sha256
preserve                = no
policy                  = policy_anything
    
[ policy_anything ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 1024
default_keyfile     = privkey.pem
distinguished_name  = req_distinguished_name
attributes          = req_attributes
x509_extensions     = v3_ca

[ req_distinguished_name ]
countryName             = Nom du pays (2 lettres)
countryName_min         = 2
countryName_max         = 2
stateOrProvinceName     = Région
localityName            = Ville
organizationalUnitName  = Unitée
commonName              = CommonName
commonName_max          = 64
emailAddress            = Email
emailAddress_max        = 64

countryName_default            = $country
stateOrProvinceName_default    = $state
localityName_default           = $town
organizationName_default       = $company
organizationalUnitName_default = $unit
emailAddress_default           = $email
# SET-ex3           = SET extension number 3

[ req_attributes ]
[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ server_cert_ssl ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ server_cert_vpn ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment

[ server_cert_mail ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

END
        cat "$pki_path/config/ACEoleCI.config"
    fi
    
    if [ ! -f "$pki_path/db/dh" ]
    then
        myopenssl dhparam \
                  -out "$pki_path/db/dh" \
                  1536
    fi
    
    if [ ! -f "$pki_path/certificats/ACEoleCI.pem" ]
    then
        echo "- Generating de la clef RSA CA..."
        rm -f ~/.rnd
        myopensslCommand "$password\\n$password\\n" \
                genrsa \
                -passout stdin \
                -des3 \
                -out "$pki_path/certificats/ACEoleCI.pem" \
                1024 
    fi
    
    if [ ! -f "$pki_path/certificats/ACEoleCI.crt" ]
    then
        echo "- Génération du certificat CA"
        #remarque c'est une AC ==> le CN = mon pnom ! ca ne doit pas être un dns !
        myopensslCommand "$password\\n$country\\n$state\\n$town\\n$company\\n$unit\\n$owner\\n$email\\n" \
                req \
                -new \
                -x509 \
                -utf8 \
                -passin stdin \
                -days 3000 \
                -config "$pki_path/config/ACEoleCI.config" \
                -extensions v3_ca \
                -subj "/C=$country/ST=$state/L=$town/O=$company/OU=$unit/CN=$owner" \
                -key "$pki_path/certificats/ACEoleCI.pem" \
                -out "$pki_path/certificats/ACEoleCI.crt"
    fi
      
    if [ ! -f "$pki_path/certificats/ACEoleCI.der" ]
    then
        echo "- Génération du certificat CA DER"
        myopenssl x509 \
                -in "$pki_path/certificats/ACEoleCI.crt" \
                -outform DER \
                -out "$pki_path/certificats/ACEoleCI.der" 
                 
    fi
}


function genereCertificatsIntermediaire()
{
  intermediaire=$1
  extension=$2
  dns=$3
  echo "----------------------------------------------- "
  echo "Intermediaire '$intermediaire'"
  echo "----------------------------------------------- "
  
  if [ ! -f "$pki_path/certificats/${intermediaire}.key" ]
  then
      echo "  Génération de la clef pour ${intermediaire} "
      myopenssl genrsa \
          -out "$pki_path/certificats/${intermediaire}.key" \
          1024 
          
      #myopenssl rsa -in "$pki_path/certificats/${intermediaire}.key" -check
  fi

  if [ ! -f "$pki_path/certificats/${intermediaire}.csr" ]
  then
      echo "  Génération du certificat : ${intermediaire}.csr"
      #genere
      myopensslCommand ".\\n.\\n.\\n.\\n.\\n$dns\\n.\\n.\\n.\\n.\\n" \
          req \
          -days 365 \
          -new \
          -config "$pki_path/config/ACEoleCI.config" \
          -extensions "${extension}" \
          -key "$pki_path/certificats/${intermediaire}.key" \
          -out "$pki_path/certificats/${intermediaire}.csr"
          
      #Check
      #myopenssl req -text -noout -verify -in $pki_path/certificats/${intermediaire}.csr      
  fi

  if [ ! -f "$pki_path/certificats/${intermediaire}.crt" ]
  then
      echo "  Signature du certificat intermediaire ${intermediaire} par la CA"
      myopensslCommand "$password\\ny\\ny\\n" \
          ca \
          -config "$pki_path/config/ACEoleCI.config" \
          -passin stdin \
          -out "$pki_path/certificats/${intermediaire}.crt" \
          -infiles "$pki_path/certificats/${intermediaire}.csr" 
  fi
  
  if [ ! -f "$pki_path/certificats/${intermediaire}.pem" ]
  then
      echo "  Concatene key+crt dans ${intermediaire}.pem"
      #$pki_path/certificats/${intermediaire}.dhp
      cat "$pki_path/certificats/${intermediaire}.key" "$pki_path/certificats/${intermediaire}.crt"  > "$pki_path/certificats/${intermediaire}.pem"
  fi

  if [ ! -f "$pki_path/certificats/${intermediaire}.p12" ]
  then
      echo "  Genere ${intermediaire}.p12"
      myopensslCommand "$password\\n$password\\n" \
           pkcs12 \
           -export \
           -password stdin \
           -in "$pki_path/certificats/${intermediaire}.crt" \
           -inkey "$pki_path/certificats/${intermediaire}.key" \
           -out "$pki_path/certificats/${intermediaire}.p12" \
           -name "admin@$dns" 
  fi

  if [ ! -f "$pki_path/certificats/${intermediaire}_avec_chaines.p12" ]
  then
     echo "  Concatene key+crt dans serveur_avec_chaines.p12"
     myopensslCommand "$password\\n$password\\n" \
           pkcs12 \
           -export \
           -password stdin \
           -in "$pki_path/certificats/${intermediaire}.crt" \
           -certfile "$pki_path/certificats/ACEoleCI.crt" \
           -inkey "$pki_path/certificats/${intermediaire}.key" \
           -out "$pki_path/certificats/${intermediaire}_avec_chaines.p12" \
           -name "admin@$dns" 
  fi
  
  if [ -f "$pki_path/certificats/${intermediaire}.crt" ]
  then
      myopenssl x509 -noout -subject -in "$pki_path/certificats/${intermediaire}.crt" 
      myopenssl x509 -noout -issuer -in "$pki_path/certificats/${intermediaire}.crt"
      
      myopenssl verify \
              -verbose \
              -purpose sslserver \
              -CAfile "$pki_path/certificats/ACEoleCI.crt" \
              "$pki_path/certificats/${intermediaire}.crt"
  fi
}

function genereCertificatsMachineFinal()
{
  repmachineEtNomKey=$1
  extension="server_cert_$2"
  fichier="${repmachineEtNomKey}-$2"
  
  if [ ! -f "${fichier}.crt" ]
  then
      echo "  Signature du certificat pour le CA"
      myopensslCommand "$password\\ny\\ny\\n" \
          ca \
          -config "$pki_path/config/ACEoleCI.config" \
          -extensions "${extension}" \
          -passin stdin \
          -out "$fichier.crt" \
          -infiles "${repmachineEtNomKey}.csr" 
  fi

  if [ ! -f "${fichier}.pem" ]
  then
     echo "  Concatene key+crt dans $fichier.pem"
      #${fichier}.dhp
     cat "${repmachineEtNomKey}.key" "${fichier}.crt"  > "${fichier}.pem"
  fi

  if [ ! -f "${fichier}.p12" ]
  then
     echo "  Genere serveur.p12"
     myopensslCommand "$password\\n$password\\n" \
           pkcs12 \
           -export \
           -password stdin \
           -in "${fichier}.crt" \
           -inkey "${repmachineEtNomKey}.key" \
           -out "${fichier}.p12" \
           -name "admin@$dns" 
  fi

  if [ ! -f "${fichier}_avec_chaines.p12" ]
  then
     echo "  Concatene key+crt dans serveur_avec_chaines.p12"
     myopensslCommand "$password\\n$password\\n" \
           pkcs12 \
           -export \
           -password stdin \
           -in "${fichier}.crt" \
           -certfile "$pki_path/certificats/ACEoleCI.crt" \
           -inkey "${repmachineEtNomKey}.key" \
           -out "${fichier}_avec_chaines.p12" \
           -name "admin@$dns" 
  fi
  
}

function genereCertificatsMachine()
{
  machine=$1
  confMachine="$EOLE_CI_TESTS_CONFIGURATION/$machine" 
  [ ! -f "$confMachine/context.sh" ] && return
  # shellcheck disable=SC1091,SC1090
  source "$confMachine/context.sh"
  
  repmachine="$EOLE_CI_TESTS_SECURITY/$machine" 
  [ -f "$repmachine" ] && return
  mkdir -p "$repmachine"
  dns=$2
  
  echo "----------------------------------------------- "
  echo "- Machine '$machine' : $dns"
  echo "----------------------------------------------- "
  
  if [ ! -f "$repmachine/serveur.key" ]
  then
      echo "  Génération de la clef pour $machine "
      myopenssl genrsa \
          -out "$repmachine/serveur.key" \
          1024
      #myopenssl rsa -in $repmachine/serveur.key -check
  fi

  if [ ! -f "$repmachine/serveur.csr" ]
  then
      echo "  Génération du certificat"
      myopensslCommand ".\\n.\\n.\\n.\\n.\\n$dns\\n.\\n.\\n.\\n.\\n" \
          req \
          -days 365 \
          -new \
          -key "$repmachine/serveur.key" \
          -out "$repmachine/serveur.csr" 
      #Check
      #myopenssl req -text -noout -verify -in $repmachine/serveur.csr      
  fi

  if [ -f "$repmachine/serveur.crt" ]
  then
      #check
      #myopenssl x509 -in $repmachine/serveur.crt -text
      #test
      #myopenssl s_client -connect $dns:443 -starttls https -showcerts
      #myopenssl s_client -starttls https -showcerts -cert $repmachine/serveur.pem
      
      myopenssl x509 -noout -subject -in "$repmachine/serveur.crt" 
      myopenssl x509 -noout -issuer -in "$repmachine/serveur.crt"
      
      myopenssl verify \
              -verbose \
              -purpose sslserver \
              -CAfile "$pki_path/certificats/ACEoleCI.crt" \
              "$repmachine/serveur.crt"
  fi

  genereCertificatsMachineFinal "$repmachine/serveur" "ssl"
  genereCertificatsMachineFinal "$repmachine/serveur" "mail"
  genereCertificatsMachineFinal "$repmachine/serveur" "vpn"
}

echo "*****************************************************************"
echo "INITIALISATION"
echo "*****************************************************************"
#attention cela supprime tout !
resetCertificats

[ ! -d "$pki_path" ]                   && mkdir "$pki_path"
[ ! -d "$pki_path/db" ]                && mkdir "$pki_path/db"
[ ! -d "$pki_path/db/ca.db.certs" ]    && mkdir "$pki_path/db/ca.db.certs"
[ ! -d "$pki_path/config" ]            && mkdir "$pki_path/config"
[ ! -d "$pki_path/certificats" ]       && mkdir "$pki_path/certificats"

set -x
checkCA
exit 0
genereCertificatsIntermediaire ACEoleCiSsl server_cert_ssl "$VM_DNSNAME"
genereCertificatsIntermediaire ACEoleCiMail server_cert_mail "$VM_DNSNAME"
genereCertificatsIntermediaire ACEoleCiVpn server_cert_vpn "$VM_DNSNAME" 

echo "*****************************************************************"
echo "Generation des machines"
echo "*****************************************************************"
machines=$(ls "$EOLE_CI_TESTS_CONFIGURATION/")
for machine in $machines  
do
    genereCertificatsMachine "$machine" "$VM_DNSNAME"
done

cat "$pki_path/db/ca.db.index"
