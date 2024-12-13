Set objShell = CreateObject("WScript.Shell")
DomainOU = objShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Distinguished-Name")
PosUN = InStr(1, DomainOU, "OU=") + 3
PosDEUX = InStr(PosUN + 1, DomainOU, "OU=") - 1
Groupe = Mid(DomainOU, PosUN, PosDEUX - PosUN)
Echo Groupe