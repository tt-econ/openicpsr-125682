#######################################################
# make.sh: Runs all scripts.
#######################################################

# clear contents of output and log directory
rm ./mex/*.mexa64
rm ./mex/private/*
rm ./log/*.log

# Start the log file
LOG=./log/make.log
echo "make.bat started"	>>$LOG
date >>$LOG

# call get_externals.sh to get the external files
bash get_externals.sh >>$LOG

# compile MEX files
matlab -r compile_mex_files -logfile compile_mex_files.log

# prepare for test scripts
mkdir test
cp ./external/lib/c/gslab_misc/test/* ./test/

# run test scripts
cd test
matlab -r run_all_tests -logfile ../log/test.log
cd ..
rm -rf test

cat compile_mex_files.log >> $LOG
rm  compile_mex_files.log >> $LOG

# End log
echo "make.bat completed" >>$LOG
date >>$LOG

