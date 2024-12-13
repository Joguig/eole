#!/bin/bash 

cd /var/lib/jenkins/ || exit 1
(
rgrep -i plugin= ./jobs/*/jobs/*/*.xml 
rgrep -i plugin= ./*.xml 
) >/tmp/allplugins
#cat /tmp/allplugins
sed -e 's/.*plugin=//' -e 's/"\/>/#/' </tmp/allplugins | sort | uniq >/tmp/allpluginversion

#ALL_PLUGINS_VERSION=$(grep ' plugin=' $JOBS |sed -e 's/.*plugin=//' -e 's/\/\>//' |sort |uniq)
#echo $ALL_PLUGINS_VERSION
while read -r V 
do
    echo "$V"
    if [ "$V" == "copy-to-slave@1.4.4\">" ]
    then
        continue
    fi
    if [ "$V" == "nodelabelparameter@1.11.0\">" ]
    then
        continue
    fi
    grep "$V" /tmp/allplugins | sort | uniq | sed -e 's/^/    /'
done </tmp/allpluginversion  