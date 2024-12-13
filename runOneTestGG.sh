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
  #echo "nettoyage : $PID_FILE" 
  if [ -f "$PID_FILE" ]
  then
     #cat "$PID_FILE"
     while read -r SOUS_PROCESSUS
     do
          #echo "Kill processus : $SOUS_PROCESSUS"
          if [[ -d /proc/$SOUS_PROCESSUS ]]
          then
              ssh root@localhost "kill -9 $SOUS_PROCESSUS" >/dev/null 2>&1
          fi
     done < "$PID_FILE" 
    [ -f "$PID_FILE" ] && /bin/rm -f "$PID_FILE"
  fi 

  echo "nettoyage : $BUILD_DIR"
  
  [ -f "$BUILD_DIR/runOneTest.sh" ] && /bin/rm "$BUILD_DIR/runOneTest.sh"
  [ -d "$WORKSPACE/EoleNebula" ] && /bin/rm -rf "$WORKSPACE/EoleNebula"
  [ -d "$WORKSPACE/one" ] && /bin/rm -rf "$WORKSPACE/one"
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
if [ -z "$JOB_NAME" ]
then
    echo "Variable JOB_NAME non définie : stop"
    exit 1
fi
if [ -z "$BUILD_NUMBER" ]
then
    echo "Variable BUILD_NUMBER non définie : stop"
    exit 1
fi

if [ -z "$WORKSPACE" ]
then
    echo "Variable WORKSPACE non définie : stop"
    exit 1
fi  

SCRIPT_PATH="${BASH_SOURCE[0]}"
if [ -h "${SCRIPT_PATH}" ]
then
  while [ -h "${SCRIPT_PATH}" ]
  do 
      SCRIPT_PATH=$(readlink "${SCRIPT_PATH}")
  done
fi
pushd . > /dev/null
DIR_SCRIPT=$(dirname "${SCRIPT_PATH}" )
cd "${DIR_SCRIPT}" > /dev/null || exit 1
SCRIPT_PATH=$(pwd);
popd  > /dev/null || exit 1
#echo "SCRIPT_PATH=$SCRIPT_PATH"

PID_FILE="$WORKSPACE/${BUILD_NUMBER}.pid"
export PID_FILE
BUILD_DIR="$WORKSPACE/$BUILD_NUMBER"
export BUILD_DIR
[ -d "$BUILD_DIR" ] && rm -rf "$BUILD_DIR"
mkdir "$BUILD_DIR"
/bin/cp -rf "$SCRIPT_PATH/"* "$BUILD_DIR"
mkdir "$BUILD_DIR/output"

# maintenant je peux trapper ...
trap trap_mesg 2 15

if [ -z "$JENKINS_URL" ]
then
    JENKINS_URL=http://jenkins.eole.lan/jenkins/
    echo "Initialise JENKINS_URL = $JENKINS_URL"
    export JENKINS_URL  
fi  

if [ -z "$JOB_URL" ]
then
    JOB_URL="$JENKINS_URL/job/$JOB_NAME/"
    echo "Initialise JOB_URL = $JOB_URL"
    export JOB_URL  
fi

if [ -z "$BUILD_URL" ]
then
    BUILD_URL="$JENKINS_URL/job/$JOB_NAME/$BUILD_NUMBER/"
    echo "Initialise BUILD_URL = $BUILD_URL"
    export BUILD_URL    
fi

ARGUMENTS="$*"
if [ "$FORCE" == "true" ] 
then
    echo "Ajout arguments : -f"
    ARGUMENTS="$ARGUMENTS -f "
fi
if [ "$FORCE_REBUILD" == "true" ] 
then
    echo "Ajout arguments : -f"
    ARGUMENTS="$ARGUMENTS -f "
fi

if [ -n "$STAGE_TEST" ]
then
    if [ "$STAGE_TEST" != "(defaut)" ]
    then
        echo "Ajout arguments : -s $STAGE_TEST"
        ARGUMENTS="$ARGUMENTS -s $STAGE_TEST"
    fi
fi

if [ "$DEBUG" == "1" ]
then
    echo "Ajout arguments : -d"
    ARGUMENTS="$ARGUMENTS -d "
fi

if [ "$DEBUG" == "2" ]
then
    echo "Ajout arguments : -d2 "
    ARGUMENTS="$ARGUMENTS -d2 "
fi

if [ -n "$BUILD_USER" ]
then
    if [ "$BUILD_USER" == 'Timer Trigger' ]
    then
        BUILD_USER=SYSTEM
        BUILD_CAUSE=TIMERTRIGGER
        export BUILD_CAUSE 
    fi
    #echo "BUILD_USER : '$BUILD_USER' "
    if [ "$BUILD_USER" != SYSTEM ]
    then
        #echo "Ajout arguments : -U $BUILD_USER "
        ARGUMENTS="$ARGUMENTS -U $BUILD_USER"
        BUILD_CAUSE=MANUALTRIGGER
        export BUILD_CAUSE 
    fi
fi

if [ "$DANS_MON_CONTEXTE" = "true" ]
then
    if [ -z "$NEBULA_PASSWORD" ]
    then
        ONE_AUTH=/home/jenkins/.one/one_auth.$BUILD_USER
        if [ -f "$ONE_AUTH" ] 
        then
            echo "ONE_AUTH=$ONE_AUTH définit par BUILD_USER/DANS_MON_CONTEXTE/node"
        else
            ONE_AUTH=/var/lib/jenkins/.one/one_auth.$BUILD_USER
            if [ -f "$ONE_AUTH" ] 
            then
                echo "ONE_AUTH=$ONE_AUTH définit par BUILD_USER/DANS_MON_CONTEXTE"
            fi
        fi
        echo "ARGUMENTS = $ARGUMENTS"
    else
        echo "Un user et mot de passe ont été donnée."
        #echo "BUILD_USER = $BUILD_USER"
        echo "ARGUMENTS = $ARGUMENTS -u $BUILD_USER:xxxxxxxxxxx"
        ARGUMENTS="$ARGUMENTS -u $BUILD_USER:$NEBULA_PASSWORD"
    fi
else
    if [ -f "$ONE_AUTH" ] 
    then
        echo "ONE_AUTH=$ONE_AUTH définit par environnement"
    else
        ONE_AUTH=/home/jenkins/.one/one_auth
        if [ -f "$ONE_AUTH" ] 
        then
            echo "ONE_AUTH=$ONE_AUTH par défaut (/home/jenkins)"
        else
            ONE_AUTH=/var/lib/jenkins/.one/one_auth
            if [ -f "$ONE_AUTH" ] 
            then
                echo "ONE_AUTH=$ONE_AUTH par défaut (jenkins)"
            else
                echo "Impossible de définir ONE_AUTH, stop!"
                exit 1
            fi
        fi
    fi
    export ONE_AUTH
    echo "ARGUMENTS = $ARGUMENTS"
fi
    
if [ ! "$NODE_NAME" = master ]
then
    export HUDSON_HOME=/home/jenkins
    export JENKINS_HOME=/home/jenkins
    
fi

cd "$WORKSPACE" || exit 1
umask 0000
/usr/lib/jvm/java-21-openjdk-amd64/bin/java \
                                 -Dfile.encoding=UTF-8 \
                                 -Djava.awt.headless=true \
                                 -Djava.net.preferIPv4Stack=true \
                                 -Djava.util.logging.config.file="$BUILD_DIR/logging.properties" \
                                 -DONE_AUTH="$ONE_AUTH" \
                                 -Duser.home="$WORKSPACE" \
                                 -Duser.dir="$BUILD_DIR" \
                                 -classpath "$BUILD_DIR/lib/*" \
                                 org.eole.Main -e /mnt/eole-ci-tests $ARGUMENTS
exitCode=$?

nettoyage
exit $exitCode