#!/bin/bash

function checkUpdate()
{
    SOURCE=$1
    DEST=$2
    SET_PERMISSION=$3

    if [ ! -f "$SOURCE" ]
    then
        echo "$SOURCE manquant !"
        return 0	
    fi
    UPDATE=0
    if [ ! -f "$DEST" ]
    then
        echo "* nouveau $DEST"
        UPDATE=1
    else
        if command -v md5sum >/dev/null 2>/dev/null
        then
        	HASH_SOURCE=$(md5sum "$SOURCE" | awk '{ print $1;}' )
        	HASH_DEST=$(md5sum "$DEST" | awk '{ print $1;}' )
        else
            if command -v sha256 >/dev/null 2>/dev/null
            then
                HASH_SOURCE=$(sha256 <"$SOURCE" )
                HASH_DEST=$(sha256 <"$DEST" )
            else
                HASH_SOURCE=$(wc -c <"$SOURCE" )
                HASH_DEST=$(wc -c <"$DEST" )
            fi
        fi
        #echo "$DEST : $HASH_SOURCE $HASH_DEST"
    	if [ "$HASH_SOURCE" != "$HASH_DEST" ]
    	then
    		echo "* update $DEST"
    		UPDATE=1
    	fi
    fi
    if [ "$UPDATE" == 1 ]
    then
        cp -v "$SOURCE" "$DEST"
    else
        echo "$DEST A JOUR"
    fi
    
    if [ "${SET_PERMISSION}" == "yes" ]
    then
        if [ ! -x "$DEST" ]
    	then
	        echo "chmod +x $DEST"
    	    chmod +x "${DEST}"
    	fi
    fi
    
    if [ "${DEST: -8}" == ".service" ] || [ "${DEST: -5}" == ".conf" ]
    then
        if [ -x "${DEST}" ]
        then
            echo "Correction droits $DEST ==> 644 !"
            chmod 644 "$DEST"
        fi
    fi

    if [ "${DEST: -8}" == ".service" ]
    then
        #RELOAD_DAEMON="1"
        service=$(basename "${DEST}")
        echo "CheckUpdateService.sh: systemctl enable '${service}'"
        systemctl disable "${service}"
        systemctl enable "${service}"
        echo "CheckUpdateService.sh: systemctl daemon-reload"
        systemctl daemon-reload
    fi

}

function deleteEolecitestsSysV()
{
    if [ -f /etc/init.d/eole-ci-tests ] 
    then
        update-rc.d -f eole-ci-tests remove
    fi
    rm -f /etc/init.d/eole-ci-tests
    rm -f /root/eole-ci-tests-daemon-runner.sh
    rm -f /root/eole-ci-tests_start.sh
    rm -f /root/daemon_runner_systemd.sh
}

if command -v systemctl > /dev/null 2>/dev/null
then
    F="/mnt/eole-ci-tests/scripts/post-install/EoleCiTestsContext$(lsb_release -rs).service"
    if [ -f "$F" ]
    then
        checkUpdate "$F" /etc/systemd/system/EoleCiTestsContext.service
    else
        checkUpdate /mnt/eole-ci-tests/scripts/post-install/EoleCiTestsContext.service /etc/systemd/system/EoleCiTestsContext.service
    fi
    
    F="/mnt/eole-ci-tests/scripts/post-install/EoleCiTestsDaemon$(lsb_release -rs).service"
    if [ -f "$F" ]
    then
        checkUpdate "$F" /etc/systemd/system/EoleCiTestsDaemon.service
    else
		checkUpdate /mnt/eole-ci-tests/scripts/post-install/EoleCiTestsDaemon.service /etc/systemd/system/EoleCiTestsDaemon.service
    fi
	deleteEolecitestsSysV
	exit 0
fi

if command -v initctl > /dev/null 2>/dev/null
then
    checkUpdate /mnt/eole-ci-tests/scripts/post-install/EoleCiTestsContext.conf /etc/init/EoleCiTestsContext.conf
    checkUpdate /mnt/eole-ci-tests/scripts/post-install/EoleCiTestsContextWait.conf /etc/init/EoleCiTestsContextWait.conf
    checkUpdate /mnt/eole-ci-tests/scripts/post-install/EoleCiTestsDaemon.conf /etc/init/EoleCiTestsDaemon.conf
    deleteEolecitestsSysV
    exit 0
fi

DISTRIB=$(uname -o)
if [ "$DISTRIB" == FreeBSD ] 
then
    mkdir -p /usr/local/etc/rc.d
    checkUpdate /mnt/eole-ci-tests/scripts/service/EoleCiTestsDaemonFreebsd.sh /root/EoleCiTestsDaemon.sh yes
    checkUpdate /mnt/eole-ci-tests/scripts/post-install/EoleCiTestsDaemon.freebsd /usr/local/etc/rc.d/EoleCiTestsDaemon yes
    checkUpdate /mnt/eole-ci-tests/scripts/post-install/config-freebsd.xml /root/config.xml
    echo 'EoleCiTestsDaemon_enable="YES"' >>/etc/rc.conf.d/EoleCiTestsDaemon
    
    service -e >/root/services_enabled.log
    service -l >/root/services_list.log
    service -rv >/root/services_run_verbose.log
    exit 0
fi

[ -f /var/run/eole-ci-tests.pid ] && rm /var/run/eole-ci-tests.pid
[ -f /etc/init.d/eole-ci-tests ] && update-rc.d -f eole-ci-tests remove
checkUpdate /mnt/eole-ci-tests/scripts/post-install/eole-ci-tests /etc/init.d/eole-ci-tests yes
chmod 755 /etc/init.d/eole-ci-tests
chown root:root /etc/init.d/eole-ci-tests
update-rc.d -f eole-ci-tests defaults 20 99

exit 0
