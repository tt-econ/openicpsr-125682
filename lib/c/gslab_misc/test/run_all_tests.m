function run_all_tests

addpath(genpath('../external/'))
addpath(genpath('../mex'))

runtests -verbose

exit