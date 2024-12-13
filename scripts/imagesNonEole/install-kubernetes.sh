#!/bin/bash
# shellcheck disable=SC2034,SC2148,SC2009

# shellcheck disable=SC1091
source /dev/stdin </mnt/eole-ci-tests/scripts/EoleCiFunctions.sh
source /dev/stdin </mnt/eole-ci-tests/scripts/imagesNonEole/functions.sh
    
echo "* Kubernetes "
if [ ! -f "/etc/lsb-release" ]
then
    echo " kubernetes doit etre ubuntu "
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
export APT_OPTS=""

if [ -f /dev/mapper/ubuntu--vg-root ]
then
    lvextend -l +100%FREE /dev/mapper/ubuntu--vg-root
    resize2fs /dev/mapper/ubuntu--vg-root
fi

doUbuntu
sshAccesRoot
apt-get install "$APT_OPTS" -y hwinfo
apt-get install "$APT_OPTS" -y less
apt-get install "$APT_OPTS" -y xauth
apt-get install "$APT_OPTS" -y iputils-ping
apt-get install "$APT_OPTS" -y dnsutils
apt-get install "$APT_OPTS" -y openssl
apt-get install "$APT_OPTS" -y python-pip
apt-get remove  "$APT_OPTS" -y lighttpd
apt-get install "$APT_OPTS" -y jq
apt-get install "$APT_OPTS" -y apt-transport-https
apt-get install "$APT_OPTS" -y curl
apt-get install "$APT_OPTS" -y ca-certificates
apt-get install "$APT_OPTS" -y gnupg
apt-get install "$APT_OPTS" -y lsb-release
apt-get install "$APT_OPTS" -y software-properties-common


#bash install-tools-docker.sh
echo "Installation Docker depuis Ubuntu !"
apt-get install "$APT_OPTS" -y docker.io
systemctl unmask docker
systemctl enable docker

mkdir -p /etc/systemd/system/docker.service.d
cat >/etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
# efface l'ancienne valeur!
ExecStart=
ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375 --dns 192.168.0.1 --dns 192.168.232.2
EOF
  
systemctl daemon-reload
systemctl restart docker

echo "* docker version"
docker version

echo "Installation de Kubernetes"

# Créer un environnement Kubernetes mono-maître avec un seul noeud.
echo "Désactive le swap ([voir les prérequis officiels](https://kubernetes.io/docs/setup/independent/install-kubeadm/#before-you-begin))"
swapoff -a

echo "Commenter la ligne swap dans /etc/fstab"
sed -i -e "/ swap / s/^/#/"  /etc/fstab

echo "Check /etc/fstab"
grep swap /etc/fstab 

echo "Installer kubeadm, kubelet et kubectl"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

K8S_CURRENT_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
curl -LO "https://dl.k8s.io/release/${K8S_CURRENT_VERSION}/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/${K8S_CURRENT_VERSION}/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

apt-get install "$APT_OPTS" -y ipvsadm
apt-get install "$APT_OPTS" -y kubelet
apt-get install "$APT_OPTS" -y kubeadm
apt-get install "$APT_OPTS" -y kubectl
apt-get install "$APT_OPTS" -y kubernetes-cni
#apt-mark hold kubelet kubeadm kubectl

echo "pré télécharger les images 'system' Kubernetes"
kubeadm config images pull

echo "Installer Nginx pour exposer l'interface web de Kubernetes"
apt-get install "$APT_OPTS" -y nginx ssl-cert

cat > admin-account.yml <<EOF
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: admin-user
      namespace: kube-system
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: admin-user
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
      - kind: ServiceAccount
        name: admin-user
        namespace: kube-system
EOF

echo "Ajout completion bash for kubectl"
#echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.
kubectl completion bash >/etc/profile.d/kubectl_completion.sh 
chmod 644 /etc/profile.d/kubectl_completion.sh

echo "Téléchargement CNI"
cd /root || exit 1
curl -L -O https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
tar -xvf cni-plugins-linux-amd64-v1.1.1.tgz
#cd /opt/cni/bin || exit 1

tagImage
exit 0