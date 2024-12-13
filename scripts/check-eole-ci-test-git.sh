#!/bin/bash
# shellcheck disable=SC2029

SCRIPT_PATH="${BASH_SOURCE[0]}"
if [ -h "${SCRIPT_PATH}" ]
then
  while [ -h "${SCRIPT_PATH}" ]
  do 
      SCRIPT_PATH=$(readlink "${SCRIPT_PATH}")
  done
fi
SCRIPT_PATH=$( D=$(dirname "${SCRIPT_PATH}"); cd "$D" && pwd || exit 1);

echo "${SCRIPT_PATH}"

GIT=$(dirname "${SCRIPT_PATH}")
MNT="$1"
if [ -z "$MNT" ]
then
   MNT=/mnt/eole-ci-tests
fi

if [ ! -d "$MNT" ]
then
    echo "usage: $0 <path-mnt-eole-ci-tests>"
    echo "   exemple check-eole-ci-test-git.sh /mnt/eole-ci-tests"
    exit 1
fi

echo "MNT = $MNT"
echo "GIT = $GIT"

diff -rq "${MNT}" "${GIT}/" >/tmp/diff
cat >/tmp/liste_ignore <<'EOF'
/: output
/: sauvegarde
/module:
status$
/dev: 
/security: 
/dev/
.git
.bak
.pyc
: serveur.
: iptable
: iproute
: ipsets
: config.non_formate
: usr$
: ssh$
/etc: ipsec
/etc: ssl
interfaces.fi
creoleget.list
parsedico.list
config.updated
config.formate
config.bak
zephir.id$
/mnt/eole-ci-tests/security
EOF
set -x
grep -v -f /tmp/liste_ignore /tmp/diff | sed -e "s#$MNT#MNT:/#" | sed -e "s#$GIT#GIT:#"  
