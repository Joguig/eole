#!/bin/bash -x

[ -z "$WORKSPACE" ] && exit 1

cd "$WORKSPACE" || exit 1

if [ ! -f "/mnt/eole-ci-tests/ModulesEole.yaml" ]
then
    echo "/mnt/eole-ci-tests non monté"
    exit 1
fi
"$WORKSPACE/scripts/shellcheck" -V

FILE_YAML=0
FILES_PS1=0
DOC_A_UPDATER=0
while read -r STATUS FILE;
do
  case "$STATUS" in
      D)
          if [ -f "/mnt/eole-ci-tests/$FILE" ]
          then
              /bin/rm "/mnt/eole-ci-tests/$FILE"
              echo "$FILE ($STATUS) delete"
          else
              echo "$FILE ($STATUS) déjà supprimé"
          fi
          ;;
      *)
          ;;
  esac
  
  if [[ -f $FILE ]]
  then
      if [[ "$FILE" =~ ^test.+(yaml)$ ]]; then
          echo "Test : $FILE"
          FILE_YAML=1
      fi

      if [[ "$FILE" =~ ^.+(ps1)$ ]]; then
          echo "File : $FILE"
          FILES_PS1=1
      fi

      if [[ "$FILE" =~ documentations ]]; then
          echo "documentations : $FILE"
          DOC_A_UPDATER=1
      fi

      if [[ "$FILE" =~ ^.+(sh)$ ]] && [[ ! "$FILE" =~ ^.+routeur_.+sh$ ]] && [[ ! "$FILE" =~ context.sh$ ]];
      then
          echo "$FILE"
          shellcheck -e SC2034 "$FILE"
          RESULT="$?"
          echo "shellcheck : $FILE ==> $RESULT"
          if [ $RESULT -ne 0 ]
          then
              if [ "$FILE" != "Jenkinsfile-build.sh" ]
              then 
                  echo -e "************** Aborting Shellcheck Error.************** " >&2
                  exit 1
              else
                  echo -e "************** Jenkinsfile-build.sh Error, ignore ************** " >&2
              fi
          fi
      fi

      if [[ "$FILE" =~ ^.+(py)$ ]];
      then
          echo "$FILE"
          pylint -E -f parseable -d E1101 "$FILE"
          RESULT="$?"
          echo "pylint : $FILE ==> $RESULT"
          if [ $RESULT -ne 0 ];
          then
              echo -e "************** Aborting Pylint Error.************** " >&2
              exit 1
          fi
      fi
  fi

  case "$STATUS" in
      D)
          if [ -f "/mnt/eole-ci-tests/$FILE" ]
          then
              /bin/rm "/mnt/eole-ci-tests/$FILE"
              echo "$FILE ($STATUS) delete"
          else
              echo "$FILE ($STATUS) déjà supprimé"
          fi
          ;;
      *)
          ;;
  esac
  

done <<< "$(git diff --name-status HEAD~1 HEAD)" 

if [ -f "/mnt/eole-ci-tests/ModulesEole.yaml" ]
then
    cd "$WORKSPACE" || exit 1
    
    #rsync --verbose --relative --recursive --links --times --exclude="output" --exclude="depots" --exclude="dev" --exclude="eoleci" --exclude=".git" --exclude="documentations" --exclude=".settings" ./* /mnt/eole-ci-tests/ >"$WORKSPACE/liste.txt"
    CDU="$?"
    [ -f "$WORKSPACE/liste.txt" ] && (cat "$WORKSPACE/liste.txt"; rm "$WORKSPACE/liste.txt")
    cp -u "$WORKSPACE/logparser-eole.rules" /mnt/eole-ci-tests/jenkins/EoleNebula/logparser-eole.rules
else
    echo "/mnt/eole-ci-tests non monté"
    exit 1
fi 

echo "YAML_UPDATE=$FILE_YAML"
if [ "$FILE_YAML" -eq 1 ] 
then
    echo "Actualise les listes"
    cd "$WORKSPACE" || exit 1
    #"$JENKINS_HOME/userContent/EoleNebula/runOneTestGG.sh" -c ListTests
else
    echo "Pas d'actualisation des Listes"
fi

echo "DOC_A_UPDATER=$DOC_A_UPDATER"
if [ "$DOC_A_UPDATER" -eq 1 ] 
then
    echo "Actualise la docs"
    cd "$WORKSPACE/documentations/"
    make clean html || exit 1
    cd /tmp/_build/html || exit 1
    ls -l 
    rsync -avP ./ documentation@dev-eole.ac-dijon.fr:eolecitests/
else
    echo "Pas d'actualisation de la documentation"
fi 

echo "FILES_PS1=$FILES_PS1"
if [ "$FILES_PS1" -eq 1 ] 
then
    echo "Actualise les Files"
    #"$JENKINS_HOME/userContent/EoleNebula/runOneTestGG.sh" -c CheckFiles
else
    echo "Pas d'actualisation des Files"
fi
exit 0 
