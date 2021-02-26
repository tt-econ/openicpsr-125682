###################
### ENVIRONMENT ###
###################
import git
import os
import sys

### SET DEFAULT PATHS
ROOT = git.Repo('.', search_parent_directories=True).working_tree_dir

PATHS = {
    'root': ROOT,
    'config': os.path.join(ROOT, 'config.yaml'),
    'config_user': os.path.join(ROOT, 'config_user.yaml'),
    'input_dir': 'input',
    'external_dir': 'external',
    'output_dir': 'output',
    'output_local_dir': 'output_local',
    'makelog': 'log/make.log',
    'output_statslog': 'log/output_stats.log',
    'output_headslog': 'log/output_heads.log',
    'source_maplog': 'log/source_map.log',
    'source_statslog': 'log/source_stats.log',
}

# LOAD TTMAKE
sys.path.insert(0, os.path.join(ROOT, 'lib'))
import ttmake as tt

### LOAD CONFIG USER
PATHS = tt.update_paths(PATHS)
tt.update_executables(PATHS)

############
### MAKE ###
############

tt.start_makelog(PATHS)

### LOG OUTPUTS
tt.log_files_in_output(PATHS)
tt.copy_link_outputs(PATHS, ['outputs.txt'])

### GET INPUT FILES
tt.remove_dir(['input', 'external'])
inputs = tt.link_inputs(PATHS, ['inputs.txt'])

### RUN SCRIPTS
tt.run_python(PATHS, program = 'code/structural_tables.py')
tt.run_matlab(PATHS, program = 'code/taxi_sim.m')
tt.run_matlab(PATHS, program = 'code/appendixfigure10.m')

### END MAKE
tt.end_makelog(PATHS)
tt.remove_dir(['temp'])
