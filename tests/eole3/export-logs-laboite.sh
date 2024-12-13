#!/bin/bash
# shellcheck disable=SC2034,SC2148

if ! command -v jq 
then
	export DEBIAN_FRONTEND=noninteractive
	apt-get install -y jq
fi

echo "*********************************************************"
echo "* Export des logs 'laboite'"

for p in $(kubectl get pods -n laboite -o json |jq '.items[].metadata.name' | sort)
do
    POD="${p//\"/}"
    kubectl logs -n laboite "$POD" >"$VM_DIR_EOLE_CI_TEST/output/$VM_OWNER/$VM_MACHINE/$POD.log"
    echo "EOLE_CI_PATH $POD.log"
done

echo "*********************************************************"
exit 0