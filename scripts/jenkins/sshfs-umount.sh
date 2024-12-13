sconnect all the SFTP mount points
# Version 2010.10.10
# Copyright (GNU GPL) Narcis Garcia
# Note: Only works with local and remote paths without spaces

Disconnect ()
{
	local LocalPath="$1"
	umount "$LocalPath"
	Result=$?
	if [ $Result -eq 0 ] ; then
		echo "	Right"
	else
		echo "($Result)"
	fi
	return $Result
}

CurrentText="$(date +'%Y-%m-%d %H:%M:%S') The SFTP accesses will be disconnected:"
echo "$CurrentText"
if [ $(id -g) -eq 0 ] ; then
	echo "$CurrentText" >>/var/log/sshfs.log
fi
MountedList="$(mount | grep -e " fuse\.sshfs ")"
if [ "$MountedList" != "" ] ; then
	IFS=$(printf "\n\b") ; for CurrentLine in $MountedList ; do unset IFS
		LocalPath="$(ReturnWord () { echo $3; }; ReturnWord $CurrentLine)"
		TempLog="/tmp/sshfs_$(echo "$LocalPath" | tr -s "/" "-" | tr -s " " "_").log"
		FirstMessage="Disconnecting $LocalPath from server $(if [ -f $TempLog ] ; then echo "(was interrupted)" ; fi)... "
		printf "$FirstMessage"
		Line1Log="$(date +'%Y-%m-%d %H:%M:%S') $FirstMessage"
		Disconnect "$LocalPath" > $TempLog 2>&1
		cat $TempLog
		if [ $(id -g) -eq 0 ] ; then
			echo "$Line1Log$(cat $TempLog)" >>/var/log/sshfs.log
		fi
		rm $TempLog
	done
else
	CurrentText="There was no mounted SFTP point."
	echo "$CurrentText"
	if [ $(id -g) -eq 0 ] ; then
		echo "$CurrentText" >>/var/log/sshfs.log
	fi
fi

