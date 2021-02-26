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
    'makelog': '',
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

### RUN SCRIPTS
tt.run_matlab(PATHS, program='code/run_noRP.m', args=str(sys.argv[1]),
              log='log/run_noRP_' + str(sys.argv[1]) + '.log')
tt.run_matlab(PATHS, program='code/run_staticRP.m', args=str(sys.argv[1]),
              log='log/run_staticRP_' + str(sys.argv[1]) + '.log')
tt.run_matlab(PATHS, program='code/run_adaptiveRP.m', args=str(sys.argv[1]),
              log='log/run_adaptiveRP_' + str(sys.argv[1]) + '.log')

tt.end_makelog(PATHS)
