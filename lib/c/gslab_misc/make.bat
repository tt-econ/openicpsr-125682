REM ****************************************************
REM * make.bat: double-click to run all scripts
REM *
REM *
REM ****************************************************

SET LOG=.\log\make.log

REM LOG START
ECHO make.bat started	>%LOG%
ECHO %DATE%		>>%LOG%
ECHO %TIME%		>>%LOG%

REM DELETE output files without deleting folders (else .svn gets deleted).
REM NOTE will not clear subfolders of output.
DEL /F /Q .\log\
DEL /F /Q .\mex\private\
dir . >>%LOG%

REM GET_EXTERNALS
get_externals externals.txt ./external/                >>%LOG% 2>&1
COPY %LOG%+get_externals.log %LOG%
DEL get_externals.log

REM COMPILE MEX FILES
matlab -r compile_mex_files -logfile compile_mex_files.log -nosplash -minimize -wait

COPY %LOG%+compile_mex_files.log %LOG%
DEL compile_mex_files.log

REM RUN TESTS
cd test
matlab -r run_all_tests -logfile ..\log\test.log -nosplash -minimize -wait
cd ..

REM LOG END
ECHO make.bat completed	>>%LOG%
ECHO %DATE%		>>%LOG%
ECHO %TIME%		>>%LOG%

PAUSE
