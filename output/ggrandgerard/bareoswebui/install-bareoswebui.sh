apt-get install docker.io

ID=$(docker build -q .)
echo "$ID"
docker tag "$ID" bareoswebui:16.2

cat >/etc/systemd/system/bareoswebui.service <<EOF
[Unit]
Description=Bareos Webui 16.2 container
BindsTo=docker.service
After=docker.service

[Service]
Restart=on-failure
RestartSec=10
ExecStartPre=-/usr/bin/docker kill bareoswebui
ExecStartPre=-/usr/bin/docker rm bareoswebui
ExecStart=/usr/bin/docker run --name bareoswebui -p 8888:80 -e BAREOS_DIR_HOST=bareos-dir -v /etc/bareos-webui:/etc/bareos-webui bareoswebui:16.2
ExecStop=/usr/bin/docker stop bareoswebui
#ExecReload=/usr/bin/docker exec bareoswebui apache ....... TOD -s reload

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bareoswebui.service
systemctl start bareoswebui.service
sleep 5
systemctl status bareoswebui.service
journalctl -xe -u bareoswebui.service --no-pager