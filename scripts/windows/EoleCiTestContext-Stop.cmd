?@echo on
C:
CD C:\eole
SC.EXE stop EoleCiTestContext
TIMEOUT 5
DEL /Q EoleCiTestContext.log
DEL /Q EoleCiTestContext.err
