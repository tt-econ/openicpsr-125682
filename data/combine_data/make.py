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
    'output_maplog': 'log/output_map.log',
    'output_statslog': 'log/output_stats.log',
    'output_headslog': '',
    'source_maplog': 'log/source_map.log',
    'source_headslog': 'log/source_heads.log',
    'source_statslog': 'log/source_stats.log'
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

### START MAKE
tt.remove_dir(['input', 'external'])
tt.clear_dir(['output', 'output_local', 'log'])
tt.clear_dir(['temp']) # For Stata scripts
tt.start_makelog(PATHS)

### GET INPUT FILES
inputs = tt.link_inputs(PATHS, ['inputs.txt'])
externals = tt.link_externals(PATHS, ['externals.txt'])
tt.write_source_logs(PATHS, inputs + externals)
tt.get_modified_sources(PATHS, inputs + externals)

### RUN SCRIPTS
tt.run_stata(PATHS, program='code/combine_data.do')

### LOG OUTPUTS
outputs = tt.copy_link_outputs(PATHS, ['outputs.txt'])
tt.log_files_in_output(PATHS, outputs)




### END MAKE
tt.end_makelog(PATHS)
tt.remove_dir(['temp']) # For Stata scripts
