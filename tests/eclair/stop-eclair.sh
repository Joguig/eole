#!/bin/bash
echo "Début $0"

echo  "kill_desktop_session: $$ killing all session processes "

# tous les processus sauf moi même($$) !
CLIENT_PID=$(pgrep LTSP_CLIENT_HOSTNAME | grep -vw -F $$)
if [ -n "$CLIENT_PID" ]
then
    kill -CONT "$CLIENT_PID" 
    sleep 3
fi
CLIENT_PID=$(pgrep LTSP_CLIENT_HOSTNAME | grep -vw -F $$)
if [ -n "$CLIENT_PID" ]
then
    kill -TERM "$CLIENT_PID" 
    sleep 3
fi
CLIENT_PID=$(pgrep LTSP_CLIENT_HOSTNAME | grep -vw -F $$)
if [ -n "$CLIENT_PID" ]
then
    kill -KILL "$CLIENT_PID" 
    sleep 3
fi
echo "kill_desktop_session: $$ finished killing"

echo "* pgrep LTSP_CLIENT_HOSTNAME"
pgrep LTSP_CLIENT_HOSTNAME
echo "exit=$?"

echo "* lsof | grep /home"
lsof | grep /home | sort | uniq

echo "* fuser -kmuv /home"
fuser -kmuv /home

echo "* umount /home"
umount -f /home

echo "pause 30 secondes"
sleep 30

echo "Fin $0"