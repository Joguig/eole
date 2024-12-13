#!/bin/bash -x

# shellcheck disable=SC1091,SC1090
source /mnt/eole-ci-tests/tests/samba/get_vars_samba.sh
export EOLE_VERSION
export SAMBA_VERSION
export DEBIAN_VERSION
export BASE
        
cd "$BASE" || exit 1
mkdir "$BASE/eole-debian-buster" 
ls -l 

cat >"$BASE/eole-debian-buster/Dockerfile" <<EOF
FROM debian:buster

ENV DEBIAN_FRONTEND noninteractive 
RUN apt-get update && apt-get install -y \ 
    build-essential \ 
    curl \ 
    devscripts \ 
    equivs \ 
    git-buildpackage \ 
    git \ 
    lsb-release \ 
    make \ 
    openssh-client \ 
    pristine-tar \ 
    rake \ 
    rsync \ 
    wget
 
EOF

docker build "$BASE/eole-debian-buster" 
ID=$(docker build -q .)
echo "$ID"
docker tag "$ID" eole-debian-buster
