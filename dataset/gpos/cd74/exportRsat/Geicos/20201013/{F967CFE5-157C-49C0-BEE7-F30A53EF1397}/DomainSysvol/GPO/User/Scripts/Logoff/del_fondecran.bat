@echo off
  
rem Suppression du cache fond ecran
del /q "%SystemDrive%\Users\%username%\AppData\Roaming\Microsoft\Windows\Themes\CachedFiles\*.*"
del /q "%SystemDrive%\Users\%username%\AppData\Roaming\Microsoft\Windows\Themes\TranscodedWallpaper"
del /q "u:\config_eole\application data\Microsoft\Windows\Themes\CachedFiles\*.*"
del /q "u:\config_eole\application data\Microsoft\Windows\Themes\TranscodedWallpaper"
