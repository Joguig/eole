#!/bin/bash -x 

ARCHIVE=http://archive.ubuntu.com/ubuntu
#TYPE=container
RELEASE=focal
VARIANT=default
ARCHITECTURE=amd64

wget https://raw.githubusercontent.com/lxc/distrobuilder/master/doc/examples/ubuntu.yaml -O ubuntu.yml

mkdir -p "/tmp/ubuntu"
cp ubuntu.yml /tmp/ubuntu/ubuntu.yml
pushd "/tmp/ubuntu" ||exit 1

/usr/bin/distrobuilder build-lxc ubuntu.yml -o image.architecture="$ARCHITECTURE" -o image.release="$RELEASE" -o image.variant="$VARIANT" -o source.url="$ARCHIVE"
ls -l
popd || exit 1
