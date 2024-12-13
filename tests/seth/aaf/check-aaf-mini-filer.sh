#!/bin/bash

# shellcheck disable=SC1091,SC1090
source /root/getVMContext.sh

echo "* getent passwd"
getent passwd
echo "* getent group"
getent group
echo "* verifier ghislaine.delmare"
if ! id ghislaine.delmare; then
    echo "utilisateur manquant"
    exit 1
fi
if [ ! -d "/home/adhomes/ghislaine.delmare" ]; then
    echo "impossible de trouver le répertoire home /home/adhomes/ghislaine.delmare"
    exit 1
fi
cat >/tmp/test_quota.py <<EOF
# -*- coding: utf-8 -*-
from fichier.quota import get_quota
q=get_quota('ghislaine.delmare');
print('Quota attendu 1024\nQuota trouvé  {}'.format(q));
try:
    assert q == 1024
except:
    print('Erreur : La restauration des quotas ne fonctionne pas : {} au lieu de 50'.format(q))
EOF
if ciVersionMajeurAPartirDe "2.8."
then
    echo "test quota pour ghislaine.delmare python3 ?"
    python3 /tmp/test_quota.py
else
    echo "test quota pour ghislaine.delmare python2 ?"
    python /tmp/test_quota.py
fi

exit 0
