###################
### ENVIRONMENT ###
###################
import git
import os
import sys

### SET DEFAULT PATHS
ROOT = git.Repo('.', search_parent_directories=True).working_tree_dir

PATHS = {
    'root'          : ROOT,
    'config_user'   : os.path.join(ROOT, 'config_user.yaml')
}

# LOAD TTMAKE
sys.path.insert(0, os.path.join(ROOT, 'lib'))
import ttmake as tt

### LOAD CONFIG USER
tt.update_executables(PATHS)

###########
### RUN ###
###########

### RUN SCRIPTS
tt.run_module(root=ROOT, module='data/combine_data')
tt.run_module(root=ROOT, module='data/minute_weather')
tt.run_module(root=ROOT, module='data/car_driver')
tt.run_module(root=ROOT, module='data/derived')
tt.run_module(root=ROOT, module='data/income_bins')
tt.run_module(root=ROOT, module='data/prepare')
tt.run_module(root=ROOT, module='data/prepare_structural')

