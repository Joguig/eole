#!/bin/bash
# EoleCi
# Copyright © 2014-2023 Pôle de Compétence Logiciels Libres EOLE <eole@ac-dijon.fr>
# 
# LICENCE PUBLIQUE DE L'UNION EUROPÉENNE v. 1.2 :
# in french: https://joinup.ec.europa.eu/sites/default/files/inline-files/EUPL%20v1_2%20FR.txt
# in english https://joinup.ec.europa.eu/sites/default/files/custom-page/attachment/2020-03/EUPL-1.2%20EN.txt

# shellcheck disable=SC2153,SC2029

function nettoyage()
{
  echo "nettoyage : $BUILD_DIR"
  [ -d "$WORKSPACE/EoleNebula" ] && /bin/rm -rf "$WORKSPACE/EoleNebula"
  [ -d "$WORKSPACE/.java" ] && /bin/rm -rf "$WORKSPACE/.java"
  if [ -n "$BUILD_DIR" ]
  then
     [ -d "$BUILD_DIR" ] && /bin/rm -rf "$BUILD_DIR"
  fi
}

function trap_mesg()
{
  trap "" 2 15
  echo "Trap message .... "
  nettoyage
  echo "Trap message fin .... "
  exit 1
}

# attention : JOB_NAME = folder "/" job !
[ -z "$JOB_NAME" ] && exit 1
[ -z "$BUILD_NUMBER" ] && exit 1
[ -z "$WORKSPACE" ] && exit 1

BUILD_DIR="$WORKSPACE/$BUILD_NUMBER"
export BUILD_DIR
[ -d "$BUILD_DIR" ] && rm -rf "$BUILD_DIR"
mv "$WORKSPACE/EoleNebula" "$BUILD_DIR"
mkdir "$BUILD_DIR/output"

# maintenant je peux trapper ...
trap trap_mesg 2 15

cd "$WORKSPACE" || exit 1
umask 0000
/usr/lib/jvm/java-21-openjdk-amd64/bin/java \
                                 -Dfile.encoding=UTF-8 \
                                 -Djava.awt.headless=true \
                                 -Djava.net.preferIPv4Stack=true \
                                 -Djava.util.logging.config.file="$BUILD_DIR/logging.properties" \
                                 -Duser.home="$WORKSPACE" \
                                 -Duser.dir="$BUILD_DIR" \
                                 -classpath "$BUILD_DIR/lib/*" \
                                 org.eole.Main -e /mnt/eole-ci-tests "$@" 2>&1
exitCode=$?

nettoyage
exit $exitCode