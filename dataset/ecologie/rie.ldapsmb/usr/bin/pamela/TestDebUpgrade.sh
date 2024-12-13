#!/bin/bash


Destinataires="pamela@equipement.gouv.fr Abonnes-Remontees-Melanie2@equipement.gouv.fr"

NfTmp=/tmp/TestDebUpgrade.$$.tmp
rm -f $NfTmp $NfTmp.1

#PATH=$PATH:/usr/sbin

#set -x

apt-get update >$NfTmp.1 2>&1
cr=$?

if [ $cr -ne 0 ]; then
 echo "Attention, apt-get update, cr=$cr" >$NfTmp
 echo >>$NfTmp
 cat $NfTmp.1 >>$NfTmp
 echo >>$NfTmp
fi



apt-get -su upgrade >$NfTmp.1  2>&1
#fgrep -q "0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded." $NfTmp.1 
grep -q "^0 .* 0 .* 0 .* 0 " $NfTmp.1 
cr=$?

if [ $cr -ne 0 ]; then
 echo "Attention, mises a jour a faire :" >>$NfTmp
 echo >>$NfTmp
 cat $NfTmp.1 >>$NfTmp
 echo >>$NfTmp
fi


if test -s $NfTmp; then
 mail -s "[ALERTE] `uname -n` Mise a jour Debian en attente" $Destinataires <$NfTmp
fi

#cat $NfTmp

rm -f $NfTmp $NfTmp.1