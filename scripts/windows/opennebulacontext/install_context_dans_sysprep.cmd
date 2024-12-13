@echo off

COPY startup.vbs c:\
COPY context.ps1 c:\
COPY unattend.xml c:\windows\system32\sysprep
rem Sysprep /generalize /oobe /shutdown /unattend:unattend.xml