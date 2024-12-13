#!/bin/bash

bash /mnt/eole-ci-tests/dataset/gpos/import_gpos_samba.sh /mnt/eole-ci-tests/dataset/gpos/aca35

ssh addc samba-tool gpo listall

echo "* fin"