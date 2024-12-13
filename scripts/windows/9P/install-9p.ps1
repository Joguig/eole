cmd /c ver
dir %windir%\System32\p9np.dll
reg query HKLM\SYSTEM\CurrentControlSet\Control\NetworkProvider /s
reg query HKLM\SYSTEM\CurrentControlSet\Services\p9np /s
reg query HKLM\SYSTEM\CurrentControlSet\Services\p9rdr /s