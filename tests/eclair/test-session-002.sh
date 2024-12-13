#!/bin/bash
echo "Début $0"
echo "whatch 300 secondes ..."
RESULT=1

SECONDS=0   # Reset $SECONDS; counting of seconds will (re)start from 0(-ish).
while (( SECONDS < 300 )); do
    echo "$SECONDS, who : "
    smbstatus
    smbstatus | grep "6a.02"
    RESULT="$?"
    if [ "$RESULT" == "0" ]
    then
        echo "Ok trouvé, Stop "
        break
    else
        echo "$SECONDS, attente !"
        sleep 10
    fi
done

echo "ps axf"
ps axf

echo "Fin $0 ==> $RESULT"
exit $RESULT
