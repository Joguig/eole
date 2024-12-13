#!/bin/bash

####################################################################################
####################################################################################
function installTools()
{
    command -v lighttpd >/dev/null 2>&1 && apt-get remove -y lighttpd
    command -v nginx >/dev/null 2>&1 && apt-get remove -y nginx
    #command -v nginx >/dev/null 2>&1 && apt-get remove -y nginx-light
    command -v samba >/dev/null 2>&1 && apt-get remove -y samba
    command -v cups >/dev/null 2>&1 && apt-get remove -y cups-daemon
    
    command -v docker >/dev/null || bash install-tools-docker.sh
    command -v systemd-docker >/dev/null || apt-get install -y systemd-docker
    apt autoremove -y
    #sysctl -w net.ipv4.ip_forward=1
    #sysctl -w net.ipv6.conf.all.forwarding=1
    #echo 1 > /proc/sys/net/ipv4/ip_forward
}

####################################################################################
####################################################################################
function configureTraefik()
{
    systemctl stop traefik.service
    cat >/root/traefik_gg.toml <<EOF
debug = true
logLevel = "DEBUG"
defaultEntryPoints = ["http", "https"]
InsecureSkipVerify = true

[web]
address = ":8080"
[web.auth.basic]
users = ["test:\$apr1\$H6uskkkW\$IgXLP6ewTrSuBkTrqE8wj/", "test2:\$apr1\$d9hr9HBB\$4HxwgUir3HP4EsggP/QNo0"]

[docker]
domain = "tuleap.ac-test.fr"
endpoint = "unix:///var/run/docker.sock"
watch = true
exposedbydefault = true
EOF

    cat >/etc/systemd/system/traefik.service <<EOF
[Unit]
Description=traefik
After=docker.service
Requires=docker.service
 
[Service]
TimeoutStartSec=120
TimeoutStopSec=15
Restart=always
RestartSec=10s
ExecStartPre=-/usr/btraefikin/docker stop traefik
ExecStartPre=-/usr/bin/docker rm traefik
ExecStartPre=/usr/bin/docker pull traefik
ExecStart=/usr/bin/systemd-docker run --rm --name traefik -p 8080:8080 -p 80:80 -v /var/run/docker.sock:/var/run/docker.sock -v /root/traefik_gg.toml:/etc/traefik/traefik.toml traefik
Type=notify
NotifyAccess=all
  
[Install]
WantedBy=multi-user.target
EOF

    chmod 644 /etc/systemd/system/traefik.service
    systemctl daemon-reload
    systemctl enable traefik.service
    
}

####################################################################################
####################################################################################
function configureNginx()
{
    apt-get install -y nginx-light
    [ ! -f /etc/nginx/cert.key ] && openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/cert.key -out /etc/nginx/cert.crt

    cat >/etc/nginx/sites-enabled/default <<EOF
server {
    listen 80;
    server_name tuleap.ac-test.fr;

    access_log            /var/log/nginx/http.access.log;
    location / {
      proxy_pass              http://localhost:8081;
      proxy_set_header        Host              \$host;
      proxy_set_header        X-Real-IP         \$remote_addr;
      proxy_set_header        X-Forwarded-For   \$proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto \$scheme;
      proxy_set_header        X-Client-Verify   \SUCCESS;
      proxy_set_header        X-Client-DN       \$ssl_client_s_dn;
      proxy_set_header        X-SSL-Subject     \$ssl_client_s_dn;
      proxy_set_header        X-SSL-Issuer      \$ssl_client_i_dn;
      proxy_read_timeout      90;
      proxy_connect_timeout   90;
      proxy_redirect          http://localhost:8081/ https//\$host/;
    }
}

server {
    listen 443;
    server_name tuleap.ac-test.fr;

    ssl on;
    ssl_certificate           /etc/nginx/cert.crt;
    ssl_certificate_key       /etc/nginx/cert.key;
    ssl_session_timeout       5m;
    ssl_protocols             TLSv1 TLSv1.1 TLSv1.2;
    ssl_session_cache         builtin:1000  shared:SSL:10m;
    ssl_prefer_server_ciphers on;
    ssl_ciphers               HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
    
    access_log            /var/log/nginx/https.access.log;

    location / {
      proxy_pass              https://localhost:8443;
      proxy_set_header        Host              \$host;
      proxy_set_header        X-Real-IP         \$remote_addr;
      proxy_set_header        X-Forwarded-For   \$proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto \$scheme;
      proxy_set_header        X-Client-Verify   \SUCCESS;
      proxy_set_header        X-Client-DN       \$ssl_client_s_dn;
      proxy_set_header        X-SSL-Subject     \$ssl_client_s_dn;
      proxy_set_header        X-SSL-Issuer      \$ssl_client_i_dn;
      proxy_read_timeout      90;
      proxy_redirect          http://localhost:8443/ https://\$host/;
    }
  }
EOF
   service nginx reload
   cat /etc/nginx/sites-enabled/default
}


####################################################################################
####################################################################################
function configureTuleap()
{
    systemctl stop Tuleap.service

    cat >/etc/systemd/system/Tuleap.service <<EOF
[Unit]
Description=Tuleap
After=docker.service
Requires=docker.service
 
[Service]
TimeoutStartSec=120
TimeoutStopSec=15
Restart=always
RestartSec=10s
ExecStartPre=-/usr/bin/docker stop tuleap
ExecStartPre=-/usr/bin/docker rm tuleap
ExecStartPre=/usr/bin/docker pull enalean/tuleap-aio
ExecStartPre=-/usr/bin/docker volume create --name tuleap-data
ExecStart=/usr/bin/systemd-docker run --rm \
                                      --name tuleap \
                                      -p 8081:80 \
                                      -p 8443:443 \
                                      -e VIRTUAL_HOST=tuleap.ac-test.fr \
                                      -v tuleap-data:/data \
                                      --label traefik.tags=tuleap \
                                      --label traefik.port=8443 \
                                      --label traefik.protocol=https \
                                      --label traefik.backend=tuleap \
                                      --label traefik.backend.rule=Host:tuleap.localhost \
                                      --label traefik.enable=true \
                                      enalean/tuleap-aio
Type=notify
NotifyAccess=all
  
[Install]
WantedBy=multi-user.target
EOF

    chmod 644 /etc/systemd/system/Tuleap.service
    systemctl daemon-reload
    systemctl enable Tuleap.service
    
    #docker exec -ti tuleap bash 
    #docker exec -ti tuleap ps axf  
    #docker exec -ti tuleap cat /data/root/.tuleap_passwd
}

####################################################################################
####################################################################################
function removeAllConteneurs()
{
    for cid in $(docker ps -a --quiet)
    do
       docker stop "$cid"
       docker rm "$cid"
    done
}

####################################################################################
####################################################################################
function testDocker()
{
    docker run -it --name=busybox1 busybox wget www.ac-dijon.fr
    busybox1Id=$(docker ps --last 1 --no-trunc --quiet)
    docker stop "$busybox1Id"
    docker rm "$busybox1Id"
}

####################################################################################
####################################################################################
function main()
{
   set -x
   #installTools
   #removeAllConteneurs
   #configureTraefik
   configureNginx
   configureTuleap
    
   echo "Stop traefik"
   systemctl stop traefik.service
    
   echo "Start Tuleap"
   systemctl start Tuleap.service
}

main


