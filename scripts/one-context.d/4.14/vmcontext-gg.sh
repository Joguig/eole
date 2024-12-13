#!/bin/bash -x

CONTEXT_DEV=$(blkid -l -t LABEL="CONTEXT" -o device)
if [ -e "$CONTEXT_DEV" ];
then
    [ ! -d /mnt/cdrom ] && mkdir /mnt/cdrom
    mount -t iso9660 -L CONTEXT -o ro /mnt/cdrom
    ONE_VARS=$(grep -E '^[a-zA-Z\-\_0-9]*=' </mnt/cdrom/context.sh | sed 's/=.*$//')

    # shellcheck disable=SC1091
    . /mnt/cdrom/context.sh

    for v in $ONE_VARS; do
        export "${v?}"
    done

    SCRIPTS_DIR="/etc/one-context.d"
    for script in "$SCRIPTS_DIR/"*
    do
        s=$(basename $script)
        cp $script "/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/${s}.sh"
        echo "------------- $script ------------"
        (
        cat $script
        echo "  ##############" 
        bash -x "$script"
        echo "  ##############"
        )  >"/mnt/eole-ci-tests/output/$VM_OWNER/$VM_ID/${s}.log" 
    done

    umount /mnt/cdrom
fi
