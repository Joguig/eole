@echo on
C:
CD C:\eole

SC.EXE stop EoleCiTestContext
TIMEOUT 5
DEL /Q EoleCiTestContext.log
DEL /Q EoleCiTestContext.err
SC.EXE start EoleCiTestContext

SC.EXE stop EoleCiTestService 
TIMEOUT 5
DEL /Q EoleCiTestService.log
DEL /Q EoleCiTestService.err
SC.EXE start EoleCiTestService 
