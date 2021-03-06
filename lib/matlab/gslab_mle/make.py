#! /usr/bin/env python
#****************************************************
# GET LIBRARY
#****************************************************
import subprocess, shutil, os
gslab_make_path = os.getenv('gslab_make_path')
subprocess.check_call('svn export --force -r 17555 ' + gslab_make_path + ' gslab_make', shell = True)
from gslab_make.py.get_externals import *
from gslab_make.py.make_log import *
from gslab_make.py.run_program import *
from gslab_make.py.dir_mod import *

#****************************************************
# MAKE.PY STARTS
#****************************************************
set_option(makelog = 'log/make.log', output_dir = './log', temp_dir = '')
start_make_logging()

# GET_EXTERNALS
get_externals('externals.txt', './external')
get_externals('depends.txt', './depend')

# ANALYSIS
run_stata(program = 'test/output_for_test_against_stata', changedir = True)
run_matlab(program = 'test/run_all_tests', changedir = True)

add_log('log/checksum.log', 'log/test.log')

end_make_logging()

shutil.rmtree('gslab_make')
raw_input('\n Press <Enter> to exit.')
