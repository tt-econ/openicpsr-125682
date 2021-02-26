# -*- coding: utf-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
from builtins import (bytes, str, open, super, range,
                      zip, round, input, int, pow, object)

# ~~~~~~~~~~~~~~~ #
# Define metadata #
# ~~~~~~~~~~~~~~~ #

makelog_started = False

color_success = None
color_failure = 'red'
color_in_process = 'cyan'
color_warning = 'magenta'
color_message = 'green'

commands = {
    'posix':
        {'makecopy': 'rsync -azh \"%s\" \"%s\"',
         'makelink': 'ln -s \"%s\" \"%s\"',
         'move': 'mv -f \"%s\" \"%s\"',
         'rmdir': 'rm %s \"%s\"',
         'mkdir': 'mkdir %s \"%s\"',
         'jupyter': '%s nbconvert --ExecutePreprocessor.timeout=-1 %s \"%s\"',
         'lyx': '%s %s \"%s\"',
         'tex': '%s %s \"%s\"',
         'math': '%s < \"%s\" %s',
         'matlab': '%s %s -r \"try addpath(\'%s\'); run(\'%s\'); catch e, fprintf(getReport(e)), exit(1); end; exit(0)\" -logfile \"%s\"',
         'perl': '%s %s \"%s\" %s',
         'python': '%s %s \"%s\" %s',
         'r': '%s %s \"%s\" %s',
         'sas': '%s %s -log -print %s',
         'st': '%s \"%s\"',
         'stata': '%s %s do \\\"%s\\\"'},
    'nt':
        {'makecopy': '%s xcopy /E /Y /Q /I /K \"%s\" \"%s\"',
         'makelink': 'mklink %s \"%s\" \"%s\"',
         'move': 'move /Y \"%s\" \"%s\"',
         'rmdir': 'rmdir %s \"%s\"',
         'mkdir': 'mkdir %s \"%s\"',
         'jupyter': '%s nbconvert --ExecutePreprocessor.timeout=-1 %s \"%s\"',
         'lyx': '%s %s \"%s\"',
         'tex': '%s %s \"%s\"',
         'math': '%s < \"%s\" %s',
         'matlab': '%s %s -r \"try addpath(\'%s\'); run(\'%s\'); catch e, fprintf(getReport(e)), exit(1); end; exit(0)\" -logfile \"%s\"',
         'perl': '%s %s \"%s\" %s',
         'python': '%s %s \"%s\" %s',
         'r': '%s %s \"%s\" %s',
         'sas': '%s %s -log -print %s',
         'st': '%s \"%s\"',
         'stata': '%s %s do \\\"%s\\\"'},
}

default_options = {
    'posix':
        {'rmdir': '-rf',
         'mkdir': '-p',
         'jupyter': '--to notebook --inplace --execute',
         'lyx': '-e pdf2',
         'tex': '-pdf -ps- -f -quiet',
         'math': '-noprompt',
         'matlab': '-nosplash -nodesktop',
         'perl': '',
         'python': '',
         'r': '--no-save',
         'sas': '',
         'st': '',
         'stata': '-e'},
    'nt':
        {'rmdir': '/s /q',
         'mkdir': '',
         'jupyter': '--to notebook --inplace --execute',
         'lyx': '-e pdf2',
         'tex': '-pdf -ps- -f -quiet',
         'math': '-noprompt',
         'matlab': '-nosplash -minimize -wait',
         'perl': '',
         'python': '',
         'r': '--no-save',
         'sas': '-nosplash',
         'st': '',
         'stata': '/e'}
}

default_executables = {
    'posix':
        {'git-lfs': 'git-lfs',
         'jupyter': 'python -m jupyter',
         'lyx': 'lyx',
         'tex': 'latexmk',
         'math': 'math',
         'matlab': 'matlab',
         'perl': 'perl',
         'python': 'python',
         'r': 'Rscript',
         'sas': 'sas',
         'st': 'st',
         'stata': 'stata-se'},
    'nt':
        {'git-lfs': 'git-lfs',
         'jupyter': 'python -m jupyter',
         'lyx': 'lyx',
         'tex':  'latexmk',
         'math': 'math',
         'matlab': 'matlab',
         'perl': 'perl',
         'python': 'python',
         'r': 'Rscript',
         'sas': 'sas',
         'st': 'st',
         'stata': 'StataSE-64'},
}

extensions = {
    'jupyter': ['.ipynb', '.IPYNB'],
    'lyx': ['.lyx', '.LYX'],
    'tex': ['.tex', '.TEX'],
    'math': ['.m', '.M'],
    'matlab': ['.m', '.M'],
    'perl': ['.pl', '.PL'],
    'python': ['.py', '.PY'],
    'r': ['.r', '.R'],
    'sas': ['.sas', '.SAS'],
    'st': ['.stc', '.STC', '.stcmd', '.STCMD'],
    'stata': ['.do', '.DO']
}
