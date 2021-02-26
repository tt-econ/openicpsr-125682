#!/bin/bash -l

#$ -l h_rt=1:00:00                # Specify the hard time limit for the job
#$ -N structural_launch           # Give job a name
#$ -j y                           # Merge the error and output streams into a single file
#$ -m bes                         # Send email when begin/end/suspend
#$ -pe omp 2                      # Request 2 cores


cd analysis/structural

qsub runscript_table3.sh
qsub runscript_table4_col134.sh
qsub runscript_table4_col2.sh
qsub runscript_table4_col5.sh
qsub runscript_appendixtables.sh
