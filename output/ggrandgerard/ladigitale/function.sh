#!/bin/bash

function getVersionArtifact()
{ 
    local POM="${1:-pom.xml}"
    VERSION=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='version']/text()" "$POM")
    if [ -z "$VERSION" ]
    then
        exit 1
    fi
    echo "$VERSION"
}

function getPropertyPom()
{ 
    local PROPERTY="$1"
    local POM="${2:-pom.xml}"
    VERSION_POM=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='properties']/*[local-name()='$PROPERTY']/text()" "$POM")
    echo "$VERSION_POM"
}

function getVersionKeycloakDocker()
{
    local DOCKERFILE="${1:-Dockerfile}"
    VERSION_DOCKER=$(sed -n '/hub.eole.education\/test\/keycloak/p'  <"$DOCKERFILE" | sed -e 's/FROM.*://' -e 's/\r//' )
    if [ -z "$VERSION_DOCKER" ]
    then
      exit 1
    fi
    echo "$VERSION_DOCKER"
}

function checkVersionKeycloakDockerVsPom()
{
    local DOCKERFILE="${1:-Dockerfile}"
    VERSION_DOCKER="$(getVersionKeycloakDocker "$DOCKERFILE")"
    if [ -z "$VERSION_DOCKER" ]
    then
      exit 1
    fi
    VERSION_POM="$(getPropertyPom 'keycloak.version')"
    if [ -z "$VERSION_POM" ]
    then
      exit 1
    fi
    if [[ "$VERSION_DOCKER" == *"$VERSION_POM"* ]] 
    then
       echo "La version Docker ($VERSION_DOCKER) et POM ($VERSION_POM) : ok "
    else
       echo "La version Docker ($VERSION_DOCKER) et POM ($VERSION_POM) n'est pas la même, stop "
       exit 1
    fi

}

function dockerCleanAll()
{
    docker ps -aq | while read -r CT
    do
        docker container rm -f "$CT"
    done
    docker container list 
}

function dockerCleanHard()
{
    dockerCleanAll
    
    docker rmi "$(docker images -a -q)"
    docker image prune -a --force
}

function displayCurl()
{
    if [ -f "$KEYCLOAK_OUTPUT_DIR/curl" ]
    then
       cat "$KEYCLOAK_OUTPUT_DIR/curl"
       rm -f "$KEYCLOAK_OUTPUT_DIR/curl"
    fi
}

function testCurl()
{
    if [ ! -f "$KEYCLOAK_OUTPUT_DIR/curl" ]
    then
        return 1
    fi
    HTTPCODE=$(awk 'NR==1 { print $2; }' "$KEYCLOAK_OUTPUT_DIR/curl")
    while (( "$#" )); do
        if [[ "$1" == "$HTTPCODE" ]];
        then
            echo "  > $HTTPCODE : OK"
            return 0
        fi
        shift
    done
    echo "  > $HTTPCODE : NOK"
    displayCurl
    exit 1
}

function waitConteneur()
{
    #echo "waitConteneur: $*"
    CONTENEUR="${1}"
    shift
    n=15;
    while [ "${n}" -gt 0 ] ;
    do
            status=$(docker inspect --format "{{json .State.Status }}" "${CONTENEUR}" 2>/dev/null)
            if [ -z "${status}" ];
            then
                echo "Waiting for ${CONTENEUR} : No status informations.";
            else
                echo "Waiting for ${CONTENEUR} up and ready (${status})...";
            fi
            if [ "\"running\"" = "${status}" ];
            then
                if [[ -z "$*" ]]
                then
                    return 0
                fi
                if docker exec "${CONTENEUR}" "$@"
                then
                    return 0
                #else
                #    echo "docker => $?"
                fi
            fi
            sleep 2;
            n=$(( n - 1))
    done;
    echo "Waiting for ${CONTENEUR} : TIMEOUT, stop !";
    return 1
}

function waitUrl()
{
    local URL="$1"
    shift
    local NB="${1:-6}"
    shift
    echo "waitUrl: $URL $NB $*"
    rm -f "$KEYCLOAK_OUTPUT_DIR/curl"
    while [ "${NB}" -gt 0 ]
    do
      curl --output "$KEYCLOAK_OUTPUT_DIR/curl" --silent --head "$URL" && CDU="$?" || CDU="$?"
      if [ "$CDU" = "0" ] 
      then
         if [[ -z "$*" ]]
         then
             if testCurl "200" "401" "303"
             then
                return 0
             fi
         else
             if testCurl "$@"
             then
                return 0
             fi
         fi
      fi
      #if [ "$CDU" = "23" ]
      #then
          # write error !
      #fi
      #if [ "$CDU" = "22" ]
      #then
         # 22 : HTTP page not retrieved. The requested url was not found or returned another error with the HTTP error code being 400 or above. 
         #      This return code only appears if -f, --fail is used.
      #fi
      #if [ "$CDU" = "7" ]
      #then
         # 7 :  Failed to connect to host. curl managed to get an IP address to the machine and it tried to setup a TCP connection to the host but failed.
         #      This can be because you have specified the wrong port number, entered the wrong host name, the wrong protocol or perhaps because there is 
         #      a firewall or another network equipment in between that blocks the traffic from getting through.
      #fi
      sleep 5
      NB=$(( NB - 1))
      echo "$NB : $CDU"
    done
    if testCurl "200"
    then
       return 0
    fi
    displayCurl
    return 1
}

function waitUrlHttp()
{
    local URL="$1"
    local NB="${2:-6}"
    #echo "waitUrl: $URL"
    rm -f "$KEYCLOAK_OUTPUT_DIR/curl"
    while [ "${NB}" -gt 0 ]
    do
      curl --output "$KEYCLOAK_OUTPUT_DIR/curl" --silent --head --fail "$URL" && CDU="$?" || CDU="$?" 
      if [ "$CDU" = "0" ] || [ "$CDU" = "22" ] || [ "$CDU" = "7" ]
      then
          HTTPCODE=$(awk 'NR==1 { print $2; }' "$KEYCLOAK_OUTPUT_DIR/curl")
      else
          HTTPCODE="-1"
      fi
           
      if [ "$HTTPCODE" = "200" ] || [ "$HTTPCODE" = "303" ] #|| [ "$HTTPCODE" = "404" ]
      then
          return 0
      fi
      sleep 5
      NB=$(( NB - 1))
    done
    displayCurl
    return 1
}


function base64_encode()
{
    declare input=${1:-$(</dev/stdin)}
    printf '%s' "${input}" | openssl enc -base64 -A
}

function base64_decode()
{
    declare input=${1:-$(</dev/stdin)}
    printf '%s' "${input}" | openssl enc -base64 -d -A
}

function json()
{
    declare input=${1:-$(</dev/stdin)}
    printf '%s' "${input}" | jq -c .
}

function curlToJson()
{
    # creation de "$KEYCLOAK_OUTPUT_DIR"/json
    grep "{" "$KEYCLOAK_OUTPUT_DIR/curl" >"$KEYCLOAK_OUTPUT_DIR"/json

    # affichage du json
    jq -M '' <"$KEYCLOAK_OUTPUT_DIR"/json
}

function jqGet()
{
    local NAME="$1"
    local JSON="$2"
    local ATTRIBUT="${3:-name}"
    
    jq '.[] | select(.'"$ATTRIBUT"' == "'"$NAME"'") | .id' -r "$KEYCLOAK_OUTPUT_DIR/${JSON}.json"
}

function getRoles()
{
    # --clientid $KC_API_CLIENT_ID
    $kcadm get roles -r "$KEYCLOAK_REALM"  >"$KEYCLOAK_OUTPUT_DIR/roles.json"
    #cat "$KEYCLOAK_OUTPUT_DIR/roles.json"
}

function getRoleId()
{
    jqGet "$1" roles name
}

function createRole()
{
    local ROLE_NAME="$1"
    local ROLE_DESC="$2"
    
    # attention GROUP_ID = global var
    ROLE_ID=$(getRoleId "$ROLE_NAME")
    if [ -n "$ROLE_ID" ]
    then
        echo "Role $ROLE_NAME already exists with id $ROLE_ID"
        return 0
    fi
    
    # --clientid $KC_API_CLIENT_ID
    if ! $kcadm create roles -r "$KEYCLOAK_REALM" -s name="$ROLE_NAME" -s "$ROLE_DESC" 
    then
        echo "Unable to create '$ROLE_NAME' role"
        return 1
    fi
    
    echo "Role $ROLE_NAME created."
    getRoles
    ROLE_ID=$(getRoleId "$ROLE_NAME")
    return 0
}

function affectGroupToRole()
{
    local GROUP_NAME="$1"
    local ROLE_NAME="$2"

    # --clientid $KC_API_CLIENT_ID
    if ! $kcadm add-roles -r "$KEYCLOAK_REALM" --gname "$GROUP_NAME" --rolename "$ROLE_NAME"
    then
        echo "Unable to affect '$GROUP_NAME' role to the '$ROLE_NAME' group"
        return 1
    else
        echo "Group $GROUP_NAME affected to $ROLE_NAME"
        return 0
    fi
}

function getGroups()
{
    $kcadm get groups -r "$KEYCLOAK_REALM" >"$KEYCLOAK_OUTPUT_DIR/groups.json"
    #cat "$KEYCLOAK_OUTPUT_DIR/groups.json"
}

function getGroupId()
{
    jqGet "$1" groups name
}

function createGroup()
{
    local GROUP_NAME="$1"

    GROUP_ID=$(getGroupId "$GROUP_NAME")
    if [ -n "$GROUP_ID" ]
    then
        echo "Group $GROUP_NAME already exists with ID = $GROUP_ID"
        return 0
    fi
    
    echo "Group $GROUP_NAME to be created."
    $kcadm create groups -r "$KEYCLOAK_REALM" -s name="$GROUP_NAME" -i 
    CDU="$?"
    if [ "$CDU" -ne "0" ]
    then
        echo "Unable to create '$GROUP_NAME' Group"
        return 1
    fi
    
    echo "Group $GROUP_NAME created."
    getGroups
}

function getUsers()
{
    $kcadm get users -r "$KEYCLOAK_REALM" >"$KEYCLOAK_OUTPUT_DIR/users.json"
    #cat "$KEYCLOAK_OUTPUT_DIR/users.json"
}

function getUserId()
{
    jqGet "$1" users username
}

function createUser()
{
    local USERNAME="$1"
    local PASSWORD="$2"
    local GROUP_ID="$3"
    
    #########################################
    # Create users
    #########################################
    USER_UID=$(getUserId "$USERNAME")
    if [ -n "$USER_UID" ]
    then
        echo "User $USERNAME already exists with ID = $USER_UID"
        return 0
    fi
    
    $kcadm create users -r "$KEYCLOAK_REALM" -s username="$USERNAME" -s enabled=true -i
    getUsers
    USER_UID=$(getUserId "$USERNAME")
    echo "UID for '$USERNAME' = $USER_UID"
    
    if ! $kcadm update "users/$USER_UID/reset-password" \
      -r "$KEYCLOAK_REALM" \
      -s type=password \
      -s value="$PASSWORD" \
      -s temporary=false \
      -n
    then
        echo "Unable to set '$USERNAME' password"
        exit 1
    else
        echo "password '$USERNAME' reset"
    fi

    if [ -z "$GROUP_ID" ]
    then
        return
    fi

    #########################################
    # Group affectations
    #########################################
    if ! $kcadm update "users/$USER_UID/groups/$GROUP_ID" \
         -r "$KEYCLOAK_REALM" \
         -s realm="$KEYCLOAK_REALM" \
         -s userId="$USER_UID" \
         -s groupId="$GROUP_ID" \
         -n
    then
        echo "Unable to affect '$USER_UID' user to the '$GROUP_ID' group"
    else
        echo "$USERNAME user affected to the '$GROUP_ID' group."
    fi
}

function loginHarbor()
{
    if [ ! -f ~/.gitlab/token ]
    then
        echo "Créer ~/.gitlab/token avec :"
        echo "HARBOR_TOKEN=<token>"
        echo "HARBOR_USERNAME=<username-harbor>"
        exit 1
    fi
    # shellcheck disable=SC1090
    source ~/.gitlab/token
    echo "$HARBOR_TOKEN" | docker login hub.eole.education -u "$HARBOR_USERNAME" --password-stdin
    return "$?" 
}

function loginKeycloack()
{
    # see : http://www.keycloak.org/docs/3.1/server_admin/topics/admin-cli.html
    #/opt/jboss/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user admin --password admin
    if $kcadm config credentials --server "$KEYCLOAK_URL" --realm "$KEYCLOAK_REALM" --user "$KEYCLOAK_USER" --password "$KEYCLOAK_PASSWORD" 
    then
        echo "logged as $KEYCLOAK_USER"
        return 0
    else
        echo "Unable to login"
        return 1
    fi
}

function createRealm()
{
    if $kcadm get "realms/$KEYCLOAK_REALM" >"$KEYCLOAK_OUTPUT_DIR/realm.json"
    then
        echo "Realm '$KEYCLOAK_REALM' already exists."
        return 0
    fi
    
    echo "Realm '$KEYCLOAK_REALM' to be created."

    #########################################
    # Create realm
    #########################################
    if REALM_ID=$($kcadm create realms -s realm="$KEYCLOAK_REALM" -s enabled=true -i)
    then
        echo "Unable to create realm $KEYCLOAK_REALM"
        return 2
    fi

    echo "Realm '$REALM_ID' created."
    $kcadm get "realms/$KEYCLOAK_REALM" >"$KEYCLOAK_OUTPUT_DIR/realm.json"
    
    if ! $kcadm update "realms/$KEYCLOAK_REALM" -s registrationAllowed=true -s rememberMe=true
    then
        echo "Unable to configure realm"
        return 3
    fi
    
    echo "Realm '$REALM_ID' configured."
    return 0
}

function getClients()
{
    $kcadm get clients -r "$KEYCLOAK_REALM" >"$KEYCLOAK_OUTPUT_DIR/clients.json"
    #cat "$KEYCLOAK_OUTPUT_DIR/clients.json"
}

function exportRealmKeys()
{
    echo "clean ouput keys..."
    rm "$KEYCLOAK_OUTPUT_DIR/"{*.pem,*.json} 2>/dev/null && echo "Output directory cleaned!"
    
    echo "Get realm keys..."
    if ! $kcadm get keys -r "$KEYCLOAK_REALM" >"$KEYCLOAK_OUTPUT_DIR/keys.json"
    then 
        echo "Unable to get realm keys"
        return 1
    fi

    jq '.keys[] | select(.algorithm == "RS256" )' -r "$KEYCLOAK_OUTPUT_DIR/keys.json" >"$KEYCLOAK_OUTPUT_DIR/keys_rs256.json"
    #cat "$KEYCLOAK_OUTPUT_DIR/keys_rs256.json"
    
    jq ".publicKey" -r "$KEYCLOAK_OUTPUT_DIR/keys_rs256.json" >"$KEYCLOAK_OUTPUT_DIR/pub.tmp"
    sed -e "1 i -----BEGIN PUBLIC KEY-----" -e "$ a -----END PUBLIC KEY-----" "$KEYCLOAK_OUTPUT_DIR/pub.tmp" > "$KEYCLOAK_OUTPUT_DIR/pub.pem"
    #cat "$KEYCLOAK_OUTPUT_DIR/pub.pem"
    rm "$KEYCLOAK_OUTPUT_DIR/pub.tmp"
    
    jq ".certificate" -r "$KEYCLOAK_OUTPUT_DIR/keys_rs256.json" >"$KEYCLOAK_OUTPUT_DIR/cert.tmp"
    sed -e "1 i -----BEGIN CERTIFICATE-----" -e "$ a -----END CERTIFICATE-----" "$KEYCLOAK_OUTPUT_DIR/cert.tmp" > "$KEYCLOAK_OUTPUT_DIR/cert.pem"
    #cat "$KEYCLOAK_OUTPUT_DIR/cert.pem"
    rm "$KEYCLOAK_OUTPUT_DIR/cert.tmp"
}

function initToolsKcAdm
{
    echo "initToolsKcAdm"
    if ! command -v jq >/dev/null 2>&1
    then
        apt install -y jq
    fi
    
    if ! command -v openssl >/dev/null 2>&1
    then
        apt install -y openssl
    fi
    
    if ! command -v curl >/dev/null 2>&1
    then
        apt install -y curl
    fi

    if ! command -v kcadm.sh
    then
        if [ ! -d "$KEYCLOAK_OUTPUT_DIR" ]
        then
            mkdir -p "$KEYCLOAK_OUTPUT_DIR"
        fi
        if [ ! -d "$KEYCLOAK_OUTPUT_DIR/kcadm.sh" ]
        then
            if ! docker cp "$KEYCLOAK_CONTAINER":/opt/keycloak/bin/client/  "$KEYCLOAK_OUTPUT_DIR/"
            then
                echo "impossible de copie kcadm/client depuis $KEYCLOAK_CONTAINER"
                return 1
            fi
            if ! docker cp "$KEYCLOAK_CONTAINER":/opt/keycloak/bin/kcadm.sh  "$KEYCLOAK_OUTPUT_DIR/"
            then
                echo "impossible de copie kcadm.sh depuis $KEYCLOAK_CONTAINER"
                return 1
            fi
        fi
    else
        kcadm="$(command -v kcadm.sh)"
    fi
    set +x
    echo "Use $kcadm"
    return 0
}

KEYCLOAK_CONTAINER="${KEYCLOAK_CONTAINER:-apps-themes}"
KEYCLOAK_URL="http://localhost:8080/auth"
KEYCLOAK_USER="admin"
KEYCLOAK_PASSWORD="admin"
KEYCLOAK_REALM="master"
KEYCLOAK_OUTPUT_DIR="/tmp/kc$$"
mkdir -p "$KEYCLOAK_OUTPUT_DIR"
trap '[ -n "$KEYCLOAK_OUTPUT_DIR" ] && /bin/rm -rf "$KEYCLOAK_OUTPUT_DIR"' EXIT

kcadm="$KEYCLOAK_OUTPUT_DIR/kcadm.sh"

