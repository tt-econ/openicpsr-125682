#!/bin/bash -l

#$ -t 1-230
#$ -l h_rt=6:00:00             # Specify the hard time limit for the job
#$ -N structural_table4_col134 # Give job a name
#$ -j y                        # Merge the error and output streams into a single file
#$ -m bes                      # Send email when begin/end/suspend
#$ -pe omp 2                   # Request 2 cores

module load python3
module load matlab

python make_table4_col134.py ${SGE_TASK_ID}

