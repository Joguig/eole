#!/bin/bash
#
# @NAME: install_bash_completions
# @AIM: Install bash completions for kubectl, helm, k3d....
# @PARAMS: None
# @RETURN: integer (0 for success)
#
install_bash_completions()
{
  mkdir -p /etc/bash_completion.d/
  kubectl completion bash >/etc/bash_completion.d/kubectl
  helm completion bash >/etc/bash_completion.d/helm

  touch ~root/.screenrc
  if ! grep -q 'startup_message off' ~root/.screenrc;
  then
    cat >>~root/.screenrc <<EOF
# Don't display the copyright page
startup_message off
EOF
  fi

  if ! grep -q 'defshell -bash' ~root/.screenrc;
  then
    cat >>~root/.screenrc <<EOF

# To enable bash completion
defshell -bash
EOF
  fi

  if ! grep -q 'defscrollback ' ~root/.screenrc;
  then
    cat >>~root/.screenrc <<EOF

# keep scrollback n lines
defscrollback 1000
EOF
  fi
}

echo "*********************************************************"
echo "*                 Eolebase3 Provisionner                *"
echo "*********************************************************"
echo

# SSH Setup
echo " SSH daemon setup "
echo "   - root login"
sed -i -e 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
echo "   - agent forwarding"

sed -i -e 's/#AllowAgentForwarding.*/AllowAgentForwarding yes/' /etc/ssh/sshd_config
echo "   - daemon restart"
systemctl restart ssh
echo

echo
# Installing Kubernetes
printf " Installing kubernetes engine %s" "microk8s "
snap install microk8s --stable --classic 2>&1 

echo
echo " Setup microk8s"

cat >>/root/.bash_aliases <<EOF
alias kubectl='microk8s.kubectl'
alias helm='microk8s.helm3'
PATH=/snap/bin:$PATH
export PATH
EOF
# shellcheck disable=SC1091
. /root/.bash_aliases

export LC_ALL=C.UTF-8
export LANG=C.UTF-8
        
echo "   - snap alises"
snap alias microk8s.kubectl kubectl
snap alias microk8s.helm3 helm

echo "   - enabling dns"
microk8s.enable dns

echo "   - enab/ling helm3"
microk8s.enable helm3
echo "   - MicroK8s status:"
echo
if ! microk8s.status --format short --wait-ready;
then
    echo "ERREUR: MicroK8s is not running !" 20
    return ${?}
fi
echo
[ "$ACTIVE_TRAEFIK" = oui ] && setup_microk8s_traefik
[ "$ACTIVE_DASHBOARD" = oui ] && setup_microk8s_dashboard

SNAP=/snap/microk8s/current
# shellcheck disable=SC1091,SC1090
. "$SNAP/actions/common/utils.sh"

#echo "* Default IP := $(get_default_ip)"
#if [ "microk8s" = "microk8s" ]; then
#  echo "* netstat "
#  netstat -ntlp
#  echo "* kubectl get all --all-namespaces "
#  kubectl get all --all-namespaces
#fi
