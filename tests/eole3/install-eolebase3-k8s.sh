#!/bin/bash
# shellcheck disable=SC2034,SC2148
CONFIGURATION="${1:-default}"

echo "*********************************************************"
echo "* EOLE 3 on k8s"
df -h

cd /root/ || exit 1

export DEBIAN_FRONTEND=noninteractive
apt-get install -y apt-transport-https 
apt-get install -y curl 
apt-get install -y apt-utils
apt-get install -y jq
apt-get install -y git

K8S_CURRENT_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
if [ ! -f /usr/bin/kubectl ]
then
    pushd /tmp 2>/dev/null || exit 1
    curl -LO "https://dl.k8s.io/release/${K8S_CURRENT_VERSION}/bin/linux/amd64/kubectl"
    curl -LO "https://dl.k8s.io/${K8S_CURRENT_VERSION}/bin/linux/amd64/kubectl.sha256"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    mv kubectl /usr/bin
    chmod +x /usr/bin/kubectl
    kubectl completion bash | tee /etc/bash_completion.d/kubectl >/dev/null
    popd 2>/dev/null ||exit 1
fi

if [ ! -f /usr/bin/kubectl-convert ]
then
    pushd /tmp 2>/dev/null || exit 1
    curl -LO "https://dl.k8s.io/release/${K8S_CURRENT_VERSION}/bin/linux/amd64/kubectl-convert"
    curl -LO "https://dl.k8s.io/${K8S_CURRENT_VERSION}/bin/linux/amd64/kubectl-convert.sha256"
    echo "$(cat kubectl-convert.sha256)  kubectl-convert" | sha256sum --check
    mv kubectl-convert /usr/bin
    chmod +x /usr/bin/kubectl-convert
    popd 2>/dev/null ||exit 1
fi

if [ ! -f /usr/bin/helm ]
then
    pushd /tmp 2>/dev/null || exit 1
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    bash ./get_helm.sh
    /usr/local/bin/helm -v
    helm plugin list
    helm plugin install https://github.com/HamzaZo/helm-adopt
    helm plugin install https://github.com/databus23/helm-diff
    helm plugin install https://github.com/komodorio/helm-dashboard.git
    helm plugin install https://github.com/JovianX/helm-release-plugin
    helm plugin list
    #curl -LO "https://get.helm.sh/helm-v3.8.1-linux-amd64.tar.gz"
    #curl -LO "https://get.helm.sh/helm-v3.8.1-linux-amd64.tar.gz.sha256sum"
    #echo "$(cat helm-v3.8.1-linux-amd64.tar.gz.sha256)  helm-v3.8.1-linux-amd64.tar.gz" | sha256sum --check
    #tar -zxvf helm-v3.8.1-linux-amd64.tar.gz -C .
    #mv linux-amd64/helm /usr/bin
    #chmod +x /usr/bin/helm
    popd 2>/dev/null ||exit 1
fi

git clone https://gitlab.mim-libre.fr/EOLE/eole-3/provisionner.git
cd provisionner || exit 1
git checkout develop

env -i bash --noprofile --norc install-eolebase3.sh 
cdu="$?"

echo "* get secret object 'admin-user' "
SECRET_ID=$(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
echo "SECRET_ID=$SECRET_ID"

echo "* Affiche secret 'admin-user' "
TOKEN=$(kubectl -n kube-system describe secret "$SECRET_ID" | awk -F' ' '/token:/ {print $2}')
echo "TOKEN=$TOKEN"
echo "$TOKEN" >"$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER/dashboard_token.log"

cd /root/ || exit 1
kubectl completion bash >/etc/profile.d/kubectl_completion.sh 
chmod 644 /etc/profile.d/kubectl_completion.sh

echo "*********************************************************"
exit "$cdu"
