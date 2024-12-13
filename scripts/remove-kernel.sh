#!/bin/bash 

function remove_kernel()
{
    local k="$1"

    if [ "$YES" != yes ]
    then
        echo "remove RC todo : $k"
        return 0
    fi
    
    echo "remove RC : $k"
    apt-get remove -y "linux-image-${k}-header" 2>/dev/null
    apt-get remove -y "linux-image-${k}-common" 2>/dev/null
    apt-get remove -y "linux-image-${k}-generic" 2>/dev/null
    apt-get autoremove -y 
    
    dpkg --purge "linux-image-${k}-generic" 2>/dev/null
    dpkg --purge "linux-image-${k}-header" 2>/dev/null
    dpkg --purge "linux-image-${k}-common" 2>/dev/null
}


YES="${1:-no}"
OLD=$(dpkg -l | tail -n +6 | grep -v -E '^rc ' | grep -E 'linux-image-[0-9]+' | grep -Fv "$(uname -r)" | awk '{ print $2;}')
for k in $OLD
do
    VERSION="${k//linux-image-/}"
    VERSION="${VERSION//-generic/}"
    remove_kernel "${VERSION}"
done
