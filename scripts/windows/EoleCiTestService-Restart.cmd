@echo on
C:
CD C:\eole
SC.EXE stop EoleCiTestService 
TIMEOUT 5
DEL /Q EoleCiTestService.log
DEL /Q EoleCiTestService.err
SC.EXE start EoleCiTestService 
