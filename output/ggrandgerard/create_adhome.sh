#!/bin/bash
login=${1}
homebasedir=${2}
userdir="${homebasedir}/${login}"
[ -d "${userdir}" ] && exit 0
mkdir -p "${userdir}"
setfacl --remove-all --recursive --remove-default "${userdir}"
chmod 700 "${userdir}"
setfacl --modify u:${login}:rwx "${userdir}"
setfacl --modify --default u:${login}:rwx "${userdir}"
