#!/bin/bash

function add_or_update_scripts()
{
    local pathScript="${1}"
    local sc
    local id
    local sourcePath
    
    sc=$(basename "${pathScript}")
    #format: <tag> ':' <value> ==> awk $3
    id=$(oneimage show "${sc}" | awk '{if ($1 == "ID") {print $3}}')
    if [[ -n "${id}" ]]
    then
        sourcePath=$(oneimage show "${id}" | awk '{if ($1 == "SOURCE") {print $3}}')
        if [[ -n "${sourcePath}" ]]
        then
            diff "${sourcePath}" "${pathScript}"
            res="$?"
            if [[ "${res}" -ne 0 ]]
            then
                oneimage rename "${id}" "${sc}-${id}"
                id=$(oneimage create --type CONTEXT --datastore "${DS_ID}" --name "${sc}" --path "${pathScript}")
                echo "  ${sc} : mis à jour ${id}"
            else
                echo "  ${sc} : à jour"
            fi
        else
            echo "  ${id} : source absente !"
        fi
    else
        id=$(oneimage create --type CONTEXT --datastore "${DS_ID}" --name "${sc}" --path "${pathScript}")
        echo "  ${sc} : $id"
    fi
}

SCRIPT_ROOT="/usr/share/eole/hapy-deploy/scripts/"
TMP_ONE_ROOT="/var/tmp/one"
SCRIPT_DEST="${TMP_ONE_ROOT}/hapy-deploy/"
ONEUSER="oneadmin"
ONEGROUP="oneadmin"

if [[ ! -e "${TMP_ONE_ROOT}" ]]
then
    mkdir -p "${TMP_ONE_ROOT}"
    chown "${ONEUSER}":"${ONEGROUP}" "${TMP_ONE_ROOT}"
fi

if [[ ! -e "${SCRIPT_DEST}" ]]
then
    mkdir -p "${SCRIPT_DEST}"
    chown "${ONEUSER}":"${ONEGROUP}" "${SCRIPT_DEST}"
fi

DEP=$(CreoleGet activer_deploiement_automatique non)
if [[ "$DEP" == "oui" ]]
then
    # Adding Main eole market
    rsync -azhv "${SCRIPT_ROOT}" "${SCRIPT_DEST}" >/dev/null

    chown -R "${ONEUSER}":"${ONEGROUP}" "${SCRIPT_DEST}"

    DS_ID=$(onedatastore list --csv --no-header -f TYPE=fil -l ID)
    
    for sc in $(ls ${SCRIPT_ROOT})
    do
        add_or_update_scripts "${SCRIPT_DEST}${sc}"
    done

    CA=$(CreoleGet zephir_ca non)
    if [[ "${CA}" == "oui" ]]
    then
        CA_FILE="$(CreoleGet zephir_ca_file)"
        CA_NAME="zephir-ca.crt"
        if [ ! -f "${CA_FILE}" ];
        then
            echo "Impossible de trouver le fichier \"$CA_FILE\", veuillez vérifier la configuration de la CA du serveur de la famille \"Déploiement automatique\""
            exit 1
        fi
        cp "${CA_FILE}" "${SCRIPT_DEST}${CA_NAME}"
        chown -R "${ONEUSER}":"${ONEGROUP}" "${SCRIPT_DEST}"

        add_or_update_scripts "${SCRIPT_DEST}${CA_NAME}"
    fi
fi

exit 0
