!define py2exeOutputDir 'dists\joineole'
!define exe 'joineole.exe'
!define onlyOneInstance
!include "FileFunc.nsh"

!insertmacro GetParameters

; Comment out the "SetCompress Off" line and uncomment
; the next line to enable compression. Startup times
; will be a little slower but the executable will be
; quite a bit smaller
;SetCompress Off
SetCompressor /FINAL /SOLID lzma

Name 'joineole'
OutFile ${exe}
SilentInstall silent
Icon 'eole.ico'

; - - - - Allow only one installer instance - - - - 
!ifdef onlyOneInstance
Function .onInit
 System::Call "kernel32::CreateMutexA(i 0, i 0, t '$(^Name)') i .r0 ?e"
 Pop $0
 StrCmp $0 0 launch
  Abort
 launch:
FunctionEnd
!endif
; - - - - Allow only one installer instance - - - - 

Section
    Var /GLOBAL WDIR
    ; Get directory from which the exe was called
    System::Call "kernel32::GetCurrentDirectory(i ${NSIS_MAX_STRLEN}, t .r0)"
    StrCpy $WDIR $0
    ; Unzip into pluginsdir
    InitPluginsDir
    SetOutPath '$PLUGINSDIR'
    File /r '${py2exeOutputDir}\*.*'
    
    ; Set working dir and execute, passing through commandline params
    SetOutPath '$0'
    ${GetParameters} $R0
    ExecWait '"$PLUGINSDIR\${exe}" "$WDIR"' $R2
    SetErrorLevel $R2
 
SectionEnd