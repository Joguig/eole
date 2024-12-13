#!/bin/bash 

if [ "$(id -u)" -ne 0 ]; 
then
    echo "need to be root in order to setup the system"
    exit 1
fi


cat >/root/check-mount-eolecitests.sh <<EOF 
#!/bin/bash
if [ -f /mnt/eole-ci-tests/ModulesEole.yaml ]
then 
    echo "ok"
else
    echo "nok"
    ls -l /mnt/eole-ci-tests
    echo "stop auto umount pour eviter les conflits"
    systemctl stop "mnt-eole\x2dci\x2dtests.automount"
    echo "umount"
    umount /mnt/eole-ci-tests
    ls -l /mnt/eole-ci-tests
    echo "restart mount avec automout"
    systemctl start "mnt-eole\x2dci\x2dtests.automount"
    echo "$?"
fi
EOF

cat >/etc/systemd/system/whatchdog-eolecitests.service <<EOF
[Unit]
Description=Vérification montage /mnt/eole-ci-tests

[Service]
ExecStart=/bin/bash /root/check-mount-eolecitests.sh
Type=oneshot
EOF

systemctl enable whatchdog-eolecitests.service
systemctl start whatchdog-eolecitests.timer

cat >/etc/systemd/system/whatchdog-eolecitests.timer <<EOF
[Unit]
Description=Timer pour lancer watchdog-eolecitests.service

[Timer]
OnCalendar=*:0,5,10,15,20,25,30,35,40,45,40,55
AccuracySec=1s

[Install]
WantedBy=multi-user.target
EOF

systemctl enable whatchdog-eolecitests.timer

cat >/etc/systemd/system/whatchdog-depots.service <<EOF
[Unit]
Description=Vérification des dépots Ubuntu /EOLE

[Service]
User=jenkins
Group=jenkins
ExecStart=-/bin/bash /mnt/eole-ci-tests/scripts/checkMajDepots.sh
Type=oneshot
EOF

systemctl enable whatchdog-depots.service

cat >/etc/systemd/system/whatchdog-depots.timer <<EOF
[Unit]
Description=Timer pour lancer watchdog-depots.service

[Timer]
OnCalendar=*:0,10,20,30,40,40
AccuracySec=1s

[Install]
WantedBy=multi-user.target
EOF

systemctl enable whatchdog-depots.timer
systemctl start whatchdog-depots.timer

systemctl daemon-reload
