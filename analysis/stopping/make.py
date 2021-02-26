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

### START MAKE
tt.remove_dir(['input', 'external'])
tt.clear_dir(['output', 'output_local', 'log'])
tt.clear_dir(['temp'])  # For Stata scripts
tt.start_makelog(PATHS)

### GET INPUT FILES
inputs = tt.link_inputs(PATHS, ['inputs.txt'])
externals = tt.link_externals(PATHS, ['externals.txt'])
tt.write_source_logs(PATHS, inputs + externals)
tt.get_modified_sources(PATHS, inputs + externals)

### RUN SCRIPTS
tt.run_stata(PATHS, program='code/create_data_with_bins.do')
tt.run_stata(PATHS, program='code/stopping_overall.do')
tt.run_stata(PATHS, program='code/get_base.do')
tt.run_stata(PATHS, program='code/figure2.do')
tt.run_stata(PATHS, program='code/stopping_gradient.do')
tt.run_stata(PATHS, program='code/appendixfigure6.do')
tt.run_stata(PATHS, program='code/figure3.do')
tt.run_stata(PATHS, program='code/appendixfigure11.do')
tt.run_stata(PATHS, program='code/prepare_square.do')
tt.run_stata(PATHS, program='code/stopping_breaks.do')
tt.run_stata(PATHS, program='code/prepare_square_breaks.do')
tt.run_r(PATHS, program='code/figures4_A9.R')
tt.run_stata(PATHS, program='code/table2.do')
tt.run_stata(PATHS, program='code/HF_prepare.do')
tt.run_stata(PATHS, program='code/regressions_with_controls.do')
tt.run_stata(PATHS, program='code/HF_regressions.do')
tt.run_stata(PATHS, program='code/appendixtable6.do')
tt.run_stata(PATHS, program='code/appendixtable7.do')
tt.run_stata(PATHS, program='code/appendixtable8.do')
tt.run_stata(PATHS, program='code/appendixtable9.do')
tt.run_stata(PATHS, program='code/appendixtables10_11.do')
tt.run_stata(PATHS, program='code/appendixtable12.do')

### LOG OUTPUTS
tt.log_files_in_output(PATHS)
tt.copy_link_outputs(PATHS, ['outputs.txt'])




### END MAKE
tt.end_makelog(PATHS)
tt.remove_dir(['temp'])  # For Stata scripts
