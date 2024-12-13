
. z:\scripts\windows\EoleCiFunctions.ps1

log "* umount Y:"
NET USE Y: /DELETE

log "* mount Y: \\eolecitest\wpkg"
NET USE Y: "\\eolecitest\wpkg" eole /USER:root /PERSISTENT:YES
if( -not ( Test-Path Y:\wpkg.js ) )
{
    log "* Y: non monte"
    $cdu = 7
    return 
}
log "* mount Y: OK"


dir y:\binaries\
Set-Location c:\eole\download
copyAll Y:\binaries

if( $env:PROCESSOR_ARCHITECTURE -eq 'AMD64' )
{ 
    log "common AMD64"
    copyAll y:\binaries\x64
}
else
{ 
    log "common X86"
    copyAll y:\binaries\x86
}

if( $VersionWindows -eq "7")
{ 
    log "install 7"
    copyAll y:\binaries\x86\Win7
}

if( $VersionWindows -eq "10.1607" )
{ 
    log "install 10.1607"
    copyAll y:\binaries\x64\Win10.1607
}

if( $VersionWindows -eq "10.1703" )
{ 
    log "install 10.1703"
    copyAll y:\binaries\x64\Win10.1703
}

if( $VersionWindows -eq "10.1709" )
{ 
    log "install 10.1709"
    copyAll y:\binaries\x64\Win10.1709
}

if( $VersionWindows -eq "10.1803" )
{ 
    log "install 10.1803"
    copyAll y:\binaries\x64\Win10.1803 
}

if( $VersionWindows -eq "10.1809" )
{ 
    log "install 10.1809"
    copyAll y:\binaries\x64\Win10.1809 
}

if( $VersionWindows -eq "10.1903" )
{ 
    log "install 10.1903"
    copyAll y:\binaries\x64\Win10.1903 
}

if( $VersionWindows -eq "10.1909" )
{ 
    log "install 10.1909"
    copyAll y:\binaries\x64\Win10.1909 
}

if( $VersionWindows -eq "10.2004" )
{ 
    log "install 10.2004"
    copyAll y:\binaries\x64\Win10.2004 
}        

Log "powercfg OFF"
powercfg -hibernate off

if( -not ( test-Path c:\util ) )
{
    log "c:\util absent"
    Expand-Archive -Path c:\eole\download\SysinternalsSuite.zip -DestinationPath c:\util
    Expand-Archive -Path c:\eole\download\TreeSizeFree.zip -DestinationPath c:\util
    Expand-Archive -Path c:\eole\download\fulleventlogview.zip -DestinationPath c:\util
    Expand-Archive -Path c:\eole\download\notepad2_4.2.25_x86.zip -DestinationPath c:\util
}
else
{
    log "c:\util présent"
}
log "* umount Y:"
NET USE Y: /DELETE

log "* install.ps1 fin"
