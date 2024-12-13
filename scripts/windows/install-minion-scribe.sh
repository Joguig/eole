#!/bin/bash

IP_SCRIBE="${1}"
echo IP_SCRIBE="$IP_SCRIBE"
IP_MACHINE="${2}"
echo IP_MACHINE="$IP_MACHINE"
VERSION_MINION="${3:-2018.3.1-Py3}"
echo VERSION_MINION="$VERSION_MINION"

iconv -f UTF-8 -t UTF-16LE >install-minion.ps1 <<EOF
Set-ExecutionPolicy Bypass -Scope Process -Force
Start-Transcript -Path "C:\\windows\\install-minion.log" -Append
Write-Host '$(date)'
Set-Location \$env:TEMP
Set-PSDebug -Trace 1
\$url = 'https://repo.saltstack.com/windows/Salt-Minion-${VERSION_MINION}-\$env:PROCESSOR_ARCHITECTURE-Setup.exe'

\$output = "\$env:TEMP\minion.exe"
\$wc = New-Object System.Net.WebClient
\$wc.DownloadFile(\$url, \$output)
Unblock-File \$output
CMD.Exe /C "\$output" /S /master=$IP_SCRIBE
Write-Host \$LastExitCode
Stop-Transcript
EOF

cat install-minion.ps1

cmd="c:\windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -InputFormat None -ExecutionPolicy Bypass -EncodedCommand $(base64 -w 0 install-minion.ps1)"
/usr/share/eole/controlevnc/cliscribe.py -e "$cmd" "$IP_MACHINE"
