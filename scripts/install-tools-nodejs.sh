#!/bin/bash

# shellcheck disable=SC1091,SC1090
#source /root/getVMContext.sh NO_DISPLAY

apt-get update

if ! command -v git >/dev/null 2>/dev/null
then
    apt-get install -y git
fi
if ! command -v make >/dev/null 2>/dev/null
then
    apt-get install -y make
fi
if ! command -v curl >/dev/null 2>/dev/null
then
    apt-get install -y curl
fi
if ! command -v gcc >/dev/null 2>/dev/null
then
    apt-get install -y build-essential gcc g++ 
fi

NODE_VERSION_A_INSTALLER=${1:-20}
echo "NODE_VERSION_A_INSTALLER=$NODE_VERSION_A_INSTALLER"

if command -v node  >/dev/null 2>/dev/null
then
    NODE_VERSION="$(node --version)"
    if [ "$NODE_VERSION" \< "v$NODE_VERSION_A_INSTALLER." ]
    then
        echo "pas la bonne version de Nodejs ($NODE_VERSION)"
        apt-get purge -y nodejs npm libnode27
        rm -rf /usr/lib/node_modules/*  
    fi
fi

if ! command -v node >/dev/null 2>/dev/null
then
    if dpkg -l |grep libnode27  >/dev/null 2>&1
    then
        apt-get remove -y libnode27
    fi
    curl -sL "https://deb.nodesource.com/setup_$NODE_VERSION_A_INSTALLER.x" | bash -
    apt-get install -y nodejs
    if ! command -v node >/dev/null 2>&1
    then
        echo "La version de Nodejs n'a pas pu être installée"
        exit 1
    fi
fi


NODE_VERSION="$(node --version)"
if [ "$NODE_VERSION" \< "v$NODE_VERSION_A_INSTALLER." ] 
then
    echo "pas la bonne version de Nodejs ($NODE_VERSION)"
    exit 1
fi 
echo "Version de Nodejs ($NODE_VERSION)"

#apt-get install -y nodejs-legacy
if ! command -v npm  >/dev/null 2>/dev/null
then
   apt-get install -y npm
fi
NPM_VERSION="$(npm --version)"
echo "Version de Npm ($NPM_VERSION)"
cd /tmp || exit 1
#apt-get install -y git-flow python-coverage pylint python-pytest vim-syntastic

git config --global core.pager 'less -R'
#touch /root/semaphore

printf "\n* lib Node"
printf "\n* **************"
NODE_LIB_PATH=/usr/lib/node_modules
ls -l "$NODE_LIB_PATH" 2>/dev/null
printf "\n* **************"

#if ! command -v yarn >/dev/null 2>/dev/null
#then
#    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
#    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
#    apt-get update
#    apt-get install -y yarn
#fi
if [ -f /etc/apt/sources.list.d/yarn.list ]
then
    apt-get remove -y yarn
    /bin/rm -f /etc/apt/sources.list.d/yarn.list
    apt-get update
fi

printf "\n* Install Npm"
[ ! -d "$NODE_LIB_PATH"/npm ] && npm install -g npm

printf "\n* Install Update"
[ ! -d "$NODE_LIB_PATH"/update ] && npm install -g update

#printf "\n* Install yarn"
#[ ! -d "$NODE_LIB_PATH"/yarn ] && npm install -g yarn

#printf "\n* Install polymer-cli"
#[ ! -d "$YARN_LIB_PATH"/polymer-cli ] && yarn global add polymer-cli

#printf "\n* Install vulcanize"
#[ ! -d "$NODE_LIB_PATH"/vulcanize ] && npm install -g vulcanize

#printf "\n* Install crisper"
#[ ! -d "$NODE_LIB_PATH"/crisper ] && npm install -g crisper

# We don't recommend using Bower for new projects. Please consider Yarn and Webpack or Parcel. 
# You can read how to migrate legacy project here: https://bower.io/blog/2017/how-to-migrate-away-from-bower/
#printf "\n* Install bower"
#[ ! -d "$NODE_LIB_PATH"/bower ] && npm install -g bower

# nsp The Node Security Platform service is shutting down 30/9/2018
#printf "\n* Install nsp"
#[ ! -d "$NODE_LIB_PATH"/nsp ] && npm install -g nsp

#printf "\n* Install 'n'"
#[ ! -d "$NODE_LIB_PATH"/n ] && npm install -g n
#[ ! -d "/usr/local/n/versions/node/${NODE_VERSION}" ] && n "${NODE_VERSION}"

printf "\n* Install mocha"
[ ! -d "$NODE_LIB_PATH"/mocha ] && npm install -g mocha

printf "\n* Install nightmare"
[ ! -d "$NODE_LIB_PATH"/nightmare ] && npm install -g nightmare

#if ! command -v gulp >/dev/null 2>/dev/null
#then
#    printf "\n* Install glup"
#    yarn global add gulp 
#fi

#if ! command -v grunt >/dev/null 2>/dev/null
#then
#    printf "\n* Install grunt"
#    yarn global add grunt 
#fi

if [ "$(sysctl -n fs.inotify.max_user_watches)" != "524288" ]
then
    echo "* fs.inotify.max_user_watches install"
    echo fs.inotify.max_user_watches=524288 | tee -a /etc/sysctl.conf && sysctl -p
else
    echo "* fs.inotify.max_user_watches OK"
fi
#n "${NODE_VERSION}"

#find / -type d \( -path /proc -o -path /sys -o -path /mnt -o -path /var/lib/lxcfs \) -prune -o -type f -newer /root/semaphore

exit 0