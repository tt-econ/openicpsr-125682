REM ****************************************************
REM * make.bat: double-click to run all scripts
REM *
REM *
REM ****************************************************

SET LOG=.\log\make.log

DEL /F /Q .\log\

REM LOG START
ECHO make.bat started	>%LOG%
ECHO %DATE%		>>%LOG%
ECHO %TIME%		>>%LOG%
dir . >>%LOG%

REM GET_EXTERNALS
get_externals externals.txt ./external/                >>%LOG% 2>&1
COPY %LOG%+get_externals.log %LOG%
DEL get_externals.log

REM DEPENDS
get_externals depends.txt ./depend/                >>%LOG% 2>&1
COPY %LOG%+get_externals.log %LOG%
DEL get_externals.log

REM COMPARE THE DELTA METHOD RESULTS IN MATLAB TO THAT IN STATA
cd test
matlab -r run_all_tests -logfile ../log/test.log -nosplash -minimize -wait
cd ..

COPY %LOG%+.\log\test.log %LOG%

REM LOG END
ECHO make.bat completed	>>%LOG%
ECHO %DATE%		>>%LOG%
ECHO %TIME%		>>%LOG%

PAUSE