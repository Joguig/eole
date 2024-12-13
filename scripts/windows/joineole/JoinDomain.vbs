Const OverWriteFiles = True

Dim Shell
Set Shell = CreateObject("WScript.Shell")

Dim objWMIService
Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")

Dim objWMIComputerSystem
Set colItems = objWMIService.ExecQuery("Select * from Win32_ComputerSystem",,48)
For Each objItem in colItems
    Set objWMIComputerSystem = objItem
Next

Dim objWMIOperatingSystem
Set colItems = objWMIService.ExecQuery("Select * from Win32_OperatingSystem",,48)
For Each objItem in colItems
    Set objWMIOperatingSystem = objItem
Next

Dim objNetwork
Set objNetwork = CreateObject("WScript.Network")

Set objArgs = Wscript.Arguments
WScript.Echo objArgs(0)
WScript.Echo objArgs(1)
WScript.Echo objArgs(2)
WScript.Echo objArgs(3)

cdu = JoinDomain( objArgs(0), objArgs(1), objArgs(2), objArgs(3) )

Set objNetwork = Nothing
Set objWMIService = Nothing
Set fso = Nothing
Set objApplication = Nothing
Set colUserEnvVars = Nothing
Set colSystemEnvVars = Nothing 
Set Shell = Nothing
WScript.quit( cdu )


Function JoinDomain ( strDomain, strUser, strPassword, strNewName)
    
    Dim strOU
    Dim strComputer, objComputer, lngReturnValue
    
    Const JOIN_DOMAIN = 1
    Const ACCT_CREATE = 2
    Const ACCT_DELETE = 4
    Const WIN9X_UPGRADE = 16
    Const DOMAIN_JOIN_IF_JOINED = 32
    Const JOIN_UNSECURE = 64
    Const MACHINE_PASSWORD_PASSED = 128
    Const DEFERRED_SPN_SET = 256
    Const INSTALL_INVOCATION = 262144
    
    strComputer = objNetwork.ComputerName
    Set OperatingSystem = GetObject("winmgmts:{authenticationlevel=Pkt," _
             & "(Shutdown)}").ExecQuery("select * from Win32_OperatingSystem where "_
             & "Primary=true")
    
    Set objComputer = GetObject("winmgmts:" _
             & "{impersonationLevel=Impersonate,authenticationLevel=Pkt}!\\" & _
             strComputer & "\root\cimv2:Win32_ComputerSystem.Name='" & _
             strComputer & "'")
    
    WScript.Echo "Test " & strComputer & " = " & strNewName
    If strComputer <> strNewName Then
        cdu = objComputer.rename( strNewName )
        If cdu <> 0 Then
            WScript.Echo "Rename failed. Error = " & Err.Number
        Else
            WScript.Echo "Rename succeeded." & " Reboot for new name to go into effect"
        End If
    End If

    Wscript.Echo "JoinDomainOrWorkGroup " & strDomain & " " & strPassword & " " & strDomain & "\" & strUser
    
    strOU = Null
    lngReturnValue = objWMIComputerSystem.JoinDomainOrWorkGroup(strDomain, strPassword, strDomain & "\" & strUser, strOU, JOIN_DOMAIN + ACCT_CREATE + DOMAIN_JOIN_IF_JOINED)
    Wscript.Echo "JoinDomainOrWorkGroup exit= " & CStr(lngReturnValue)
    
    Select Case lngReturnValue
        ' Some return code values (added 04/05/2010).
        Case 0
            Wscript.Echo "Success joining computer to the domain!"
        Case 5
            Wscript.Echo "Access is denied"
        Case 87
            Wscript.Echo "The parameter is incorrect"
        Case 110
            Wscript.Echo "The system cannot open the specified object"
        Case 1323
            Wscript.Echo "Unable to update the password"
        Case 1326
            Wscript.Echo "Logon failure: unknown username or bad password"
        Case 1355
            Wscript.Echo "The specified domain either does not exist or could not be contacted"
        Case 2224
            Wscript.Echo "The account already exists"
        Case 2691
            Wscript.Echo "The machine is already joined to the domain"
        Case 2692
            Wscript.Echo "The machine is not currently joined to a domain"
        Case Else
            Wscript.Echo "Unknown error"
    End Select
    JoinDomain = lngReturnValue
    
End Function

