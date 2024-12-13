#!/bin/bash -e
# shellcheck disable=SC2034,SC2148

DOMAIN_DNS="$1"
if [ -z "$DOMAIN_DNS" ]
then
    echo "DOMAIN_DNS inconnu !"
    exit 1
fi

echo "*********************************************************"
echo "* Importation laboite (context: $DOMAIN_DNS)"

echo "Readme at : https://codimd.mim-libre.fr/No04nP4eTiCxBO1dXTOxzw#"

mkdir -p /root/laboite 
cd /root/laboite || exit 1

echo "* install dépendance"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y git 
apt-get install -y python3-jinja2  
apt-get install -y python3-click
apt-get install -y jq

echo "* creater /root/.kube/config"
mkdir /root/.kube
k3d kubeconfig get eole3 >/root/.kube/config
chown "$(id -u)":"$(id -g)" /root/.kube/config
# WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: /root/.kube/config --> chmod 600 /root/.kube/config
chmod 600 /root/.kube/config
cat /root/.kube/config >"$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER/$VM_MACHINE/kube_config.json"

kubectl cluster-info dump >"$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER/$VM_MACHINE/kubectl_cluster-info_dump.json"

echo "*********************************************************"
echo "* télécharge venv"
apt update
apt install python3-venv --assume-yes

echo "*********************************************************"
echo "create venv Eole3"
python3 -m venv ~/laboite/.venv/eole3

echo "*********************************************************"
echo "activate venv"
# shellcheck disable=SC1091,SC1090
source ~/laboite/.venv/eole3/bin/activate

echo "*********************************************************"
echo "Install eole3 tool"
pip install git+https://gitlab.mim-libre.fr/EOLE/eole-3/tools.git@dev

echo "*********************************************************"
echo "Completion"
eval "$(_EOLE3_COMPLETE=bash_source eole3)"

cd /root/laboite/
eole3 --config eole3.yaml build socle

echo "*********************************************************"
echo "* cp tls"
cp -v /mnt/cdrom/*.key /root/laboite/install/infra/ingress-nginx/tls.key
cp -v /mnt/cdrom/*.crt /root/laboite/install/infra/ingress-nginx/tls.crt

echo "  Affiche info certificat /root/laboite/install/infra/ingress-nginx/tls.crt"
openssl x509 -in /root/laboite/install/infra/ingress-nginx/tls.crt -noout -issuer -subject -dates | sed 's/^/    /'

SUBJECT=$(openssl x509 -in /root/laboite/install/infra/ingress-nginx/tls.crt -noout -subject | sed 's/^subject=CN = *.//')
echo "SUBJECT DNS CRT = ${SUBJECT} vs ${DOMAIN_DNS}"

echo "*********************************************************"
echo "* sauvegarde eole3.yaml dans eole3.depot "
cp eole3.yaml eole3.depot

echo "*********************************************************"
echo "* création eole3.yaml"
ADMIN_PWD="\$Pass&123456\$"
echo "ADMIN_PWD=${ADMIN_PWD}"

cat >eole3.yaml <<EOF
default:
  #Vars that concern all sections below
  #general domain for the deployment
  domain: ${DOMAIN_DNS}
  ingress:
    #Ingress controller choice : [nginx]
    controller: nginx
    className: nginx

  namespace: laboite
  registry: hub.eole.education

  #Globaly deactivate persistence
  demoMode: False
  #All the parameters below can be override in components sections
  chart:
    repoUrl: https://hub.eole.education/chartrepo/eole
  resources:
    requests:
      cpu: 300m
      memory: 300Mi
    limits:
      cpu: 600m
      memory: 600Mi
  autoscaling:
    enabled: False
    minReplicas: 1
    maxReplicas: 3
    cpuAverageUtilization: 60
  #endpoints for prometheus
  metrics:
    enabled: False
  #services monitor for prometheus operator
  serviceMonitor:
    enabled: False

  database:
    #'type' must be 'external', 'socle' or 'subchart'
    # If type: socle, it will deploy the 'provider' chart (eg. postgresql chart)
    type: socle
    #'provider' must be the name of database engine section (eg. '[postgresql]')
    provider: postgresql
    #If False, 'appDatabase', 'appUser' and 'addPassword' must already exist on external db server
    manageDatabase: True
    # 'adminUser' and 'adminDatabase' are not used if 'type : = socle'
    admin:
      user: postgres
      password: changeme
      dbname: postgres

  s3:
    type: socle
    provider: minio
    createAccess: True
    admin:
      accessKey: root
      secretKey: changeme

  smtp:
    #Parameters for smtp server
    protocol: smtps
    hostname: 192.168.0.1
    #port: 25
    tls: False
    username: ''
    password: ''
    from_address: ne-pas-repondre-apps@education.fr

cert-manager:
  #Install cert-manager
  deploy: False
  #Use already installed cert-manager
  enabled: False
  clusterIssuerName: laboite-clusterissuer
  #Choose between prod or staging
  type: staging
  email: eole@ac-dijon.fr
  namespace: cert-manager

  chart:
    #imageTag:
    version: v1.10.0
    repoUrl: https://charts.jetstack.io

ingress-nginx:
  deploy: True
  namespace: ingress-nginx
  #Name of the resource for the secret in kubernetes
  tlsSecret: tls-secret
  grafana:
    dashboardId: 15910
    dashboardRev: 1
  #Enable proxyprotocol for realip
  #depends on cloud provider
  #only scaleway supported for now
  cloudProvider: unknown
  # Force the LoadBalancerIP
  #loadBalancerIP: 192.0.2.12

  chart:
    version: 4.9.0
    repoUrl: https://kubernetes.github.io/ingress-nginx

coredns:
  #Section about internal kubernetes cluster CoreDns server
  #Don't touch this section unless you know what you're doing
  patch: False
  dns: 192.168.0.1

laboite:
  #Section about laboite application
  enabled: True
  #General domain will be appended to this hostname
  hostname: portail
  whitelistIps: 0.0.0.0/0
  #Meteor_settings.json parameters for laboite
  appName: LaBoîte
  appDescription: Sac à dos numérique de l’agent public
  theme: eole
  cspFrameAncestors: '*.eole3.dev'
  whiteDomains:
    - "^ac-[a-z-]*\\.fr"
    - "^[a-z-]*\\.gouv.fr"

  s3:
    buckets:
      - apps
    accessKey: laboite
    secretKey: changeme

  chart:
    version: 1.8.2
    repoUrl: https://hub.eole.education/chartrepo/eole

keycloak:
  enabled: True
  #General domain will domain will be appended to this hostname
  hostname: auth
  #Keycloak realm name for laboite
  realm: laboite
  realmImport: False
  #Default locale for the realm
  defaultLocale: fr
  #Keycloak client name
  client: sso
  clientName: sso
  clientPublicAccess: True
  #Set the fqdn's of each apps that are allowed to use the sso client
  #laboite fqdn is automatically added
  #You can write \$domain or \${domain} to set the general domain
  redirectUris:
    - https://agenda.${DOMAIN_DNS}/*
    - https://blog.${DOMAIN_DNS}/*
    - https://blogapi.${DOMAIN_DNS}/*
    - https://mezig.${DOMAIN_DNS}/*
    - https://sondage.${DOMAIN_DNS}/*
    - https://questionnaire.${DOMAIN_DNS}/*
  adminUser: keycloak
  adminPassword: changeme
  #Keycloak user for group managment
  admapiUser: admapi
  adminapiPassword: changeme
  #Keycloak public key (automatically generated at installation)
  pubkey: changeme
  #Backup for keycloak database
  enableBackup: False
  #Cron expression for how to backup keycloak database
  scheduleBackup: 0 0 * * *
  backupPvcSize: 20Gi
  #Cluster resources parameters
  grafana:
    dashboardId: 19659
    dashboardRev: 1

  chart:
    imageTag: 22.0.3-eole3.4
    name: keycloakx
    version: 2.2.1
    repoUrl: https://codecentric.github.io/helm-charts
  #Keep empty to use general values
  resources:
    requests:
      cpu: 1
      memory: 1024Mi
    limits:
      cpu: 2
      memory: 2048Mi
  autoscaling:
    enabled: True
    minReplicas: 2

  database:
    user: keycloak
    password: keycloak
    dbname: keycloak

franceTransfert:
  apiKey: ''
  endpoint: ''

BBB:
  #Parameters for Big Blue Button
  enable: 'false'
  url: ''
  secret: ''

minio:
  #Parameters for minio S3
  #If True, deploy internal minio server
  deploy: True
  #Adapt all parameters below to you're minio configuration
  #Credentials for admin user account
  hostname: minio
  admin:
    accessKey: root
    secretKey: changeme
  #Files size limits
  fileSize: 500000
  storageFilesSize: 30000000
  maxDiskPerUser: 100000000
  #Backup for minio
  enableBackup: False
  #Cron expression for how to backup minio
  scheduleBackup: 0 0 * * *
  backupPvcSize: 20Gi

  chart:
    version: 5.0.14
    repoUrl: https://charts.min.io
  resources:
    requests:
      memory: 1Gi

postgresql:
  deploy: True
  namespace: postgresql
  hostname: postgresql
  port: "5432"
  # only adminPassword can be set in 'bitnami/postgresql' chart
  admin:
    password: changeme
  # tag: 15.3.0-debian-11-r7

  chart:
    version: 12.5.8
    repoUrl: https://charts.bitnami.com/bitnami

mongodb:
  #Parameters for mongodb server
  #If True, deploy internal mongodb server
  deploy: True
  namespace: laboite
  #Internal name and port for mongodb server
  mongoName: mongo-laboite
  mongoPort: 27017
  #Name of mongodb database for laboite
  mongoDatabase: laboite
  #Root password
  mongoRootPassword: changeme
  #User and password for laboite to access database
  mongoUsername: laboite
  mongoPassword: changeme
  #ReplicaSet name for mongodb. Don't touch this unless you know what know
  mongoRsname: rs0
  #Backup for mongodb database
  enableBackup: False
  #Cron expression for how to backup mongodb database
  scheduleBackup: 0 0 * * *
  backupPvcSize: 20Gi
  #use this command on primary BEFORE changing master version
  #db.adminCommand( { setFeatureCompatibilityVersion: "<MASTER_VERSION>" } )
  #tag: 6.0.3-debian-11-r0
  grafana:
    dashboardId: 14997
    dashboardRev: 1

  chart:
    version: 13.16.4
    repoUrl: https://charts.bitnami.com/bitnami

mezig:
  #If True, deploy subchart
  deploy: True
  #General domain will domain will be appended to this hostname
  hostname: mezig
  whitelistIps: 0.0.0.0/0
  #chart:
  #  imageTag:

agenda:
  #If True, deploy subchart
  deploy: True
  #General domain will domain will be appended to this hostname
  hostname: agenda
  whitelistIps: 0.0.0.0/0
  #chart:
  #  imageTag:

sondage:
  #If True, deploy subchart
  deploy: True
  #General domain will domain will be appended to this hostname
  hostname: sondage
  whitelistIps: 0.0.0.0/0
  #chart:
  #  imageTag: 1.4.0

lookup-server:
  #If True, deploy subchart
  deploy: True
  #General domain will domain will be appended to this hostname
  hostname: lookup-server
  whitelistIps: 0.0.0.0/0
  #chart:
  #  imageTag:

radicale:
  #If True, deploy subchart
  deploy: True
  #General domain will domain will be appended to this hostname
  hostname: caldav
  whitelistIps: 0.0.0.0/0
  #chart:
  #  imageTag:

blog:
  #If True, deploy subchart
  deploy: True
  #General domain will domain will be appended to this hostname
  hostname: blog
  whitelistIps: 0.0.0.0/0
  chart:
    image: laboite-blog_front
  # imageTag: 1.3.0

blogapi:
  #Will be deploy if blog.deploy :  True
  #General domain will domain will be appended to this hostname
  hostname: blogapi
  whitelistIps: 0.0.0.0/0
  chart:
    image: laboite-blog_api
  #  imageTag: 1.3.0

frontnxt:
  #If True, deploy subchart
  deploy: True
  #General domain will domain will be appended to this hostname
  hostname: frontnxt
  whitelistIps: 0.0.0.0/0
  chart:
    image: frontal-nextcloud
    #imageTag: 1.0.1

questionnaire:
  #If True, deploy subchart
  deploy: False
  #General domain will domain will be appended to this hostname
  hostname: questionnaire
  whitelistIps: 0.0.0.0/0
  cronEnabled: False
  cronSchedule: 2 0 * * *
  cronScript: /dataSuppressor/purgeData.py
  cronTag: 1.0.0
  #chart:
  #  imageTag:

nextcloud:
  #Parameters for meteor settings
  enable: 'false'
  hideGroupPlugins: 'true'
  url: nuage.${DOMAIN_DNS}
  circlesUser: circles_user
  circlesPassword: circles_password
  nextcloudUser: nextcloud_user
  nextcloudPassword: nextcloud_password
  nextcloudQuota: 1073741824
  nextcloudApiKeys: une-cle-api-de-ton-choix
  sessionTokenKey: MCM
  sessionTokenAppName: eole3.glaude

laboite-api:
  #If True, deploy subchart
  deploy: False
  #General domain will domain will be appended to this hostname
  hostname: laboite-api
  whitelistIps: 0.0.0.0/0
  #chart:
  #  imageTag:

grafana:
  hostname: grafana
  dashboard-folder: Eole3
  admin-password: changeme
EOF

sed -i "s/eole3.dev/${DOMAIN_DNS}/" eole3.yaml
sed -i "s/patch=false/patch=true/" eole3.yaml
ciAfficheContenuFichier eole3.yaml

echo "*********************************************************"
echo "Déploiement de la boîte"
eole3 deploy socle
ciCheckExitCode "$?" "deploy"

echo "*********************************************************"
echo "* Fin ==> attente Running"
for (( i=1; i<1200 ; i+=30 ));
do
    echo "*********************************************************"
    echo "* kubectl get pods -n laboite"
    kubectl get pods -n laboite | tee /tmp/getpods
    NB="$(grep -c Running /tmp/getpods)"
    echo "* NB running = $NB"
    if [ "${NB}" -gt 16 ]
    then
        echo "stop. Je n'attends pas les autres !"
        break
    fi
    echo "$SECONDS, attente !"
    sleep 30
done

echo "*********************************************************"
exit 0