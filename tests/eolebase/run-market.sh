#!/bin/bash 

set -xe

WORKDIR=/tmp/test
mkdir -p "$WORKDIR"

sudo apt-get install -y qemu-utils qemu-kvm ovmf

IMAGE=eolebase-2.9.0
APP_ID=13cdf003-e94d-4e39-b242-fada6edc89a1
URL="https://magasin.eole.education/appliance/${APP_ID}"

if [ ! -f "${WORKDIR}/${IMAGE}.qcow2" ]
then
    if [ ! -f "${WORKDIR}/${IMAGE}.qcow2.bz2" ]
    then
        wget --progress=dot -e dotbytes=10M -c --no-http-keep-alive -O "${WORKDIR}/${IMAGE}.qcow2.bz2" "$URL/download/0"
    fi
    if [ ! -f "${WORKDIR}/${IMAGE}.qcow2" ]
    then
        bunzip2 "${WORKDIR}/${IMAGE}.qcow2.bz2"
    fi
fi

if [ ! -f "${WORKDIR}/${IMAGE}-a.qcow2" ]
then
    qemu-img create -f qcow2 "${WORKDIR}/${IMAGE}-a.qcow2" 10G
fi
#if [ ! -f "${WORKDIR}/OVMF_VARS.flash" ]
#then
#    cp /usr/share/ovmf/OVMF_VARS.fd "${WORKDIR}/OVMF_VARS.flash"
#fi
if [ ! -f "${WORKDIR}/OVMF.fd" ]
then
    cp /usr/share/ovmf/OVMF.fd "${WORKDIR}/OVMF.fd"
fi

sudo qemu-system-x86_64 \
         -machine q35,smm=on,accel=kvm \
         -cpu host \
         -smp cores=4 \
         -m 6144 \
         -global driver=cfi.pflash01,property=secure,value=on \
         -boot menu=on \
         -drive if=pflash,format=raw,unit=0,file="${WORKDIR}/OVMF.fd" \
         -global ICH9-LPC.disable_s3=1 \
         -global isa-debugcon.iobase=0x402 -debugcon "file:/tmp/eole.ovmf.log" \
         -netdev id=net0,type=user -device virtio-net-pci,netdev=net0,romfile= \
         -drive id=disk0,file="${WORKDIR}/${IMAGE}.qcow2",if=none,format=qcow2 -device virtio-blk-pci,drive=disk0,bootindex=0 \
         -rtc base=localtime,clock=host \
         -device piix3-usb-uhci -device usb-tablet \
         -device qxl-vga \
         -k fr
