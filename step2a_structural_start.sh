#!/bin/bash -l

#$ -l h_rt=01:00:00        # Specify the hard time limit for the job
#$ -N structural_start     # Give job a name
#$ -j y                    # Merge the error and output streams into a single file
#$ -m bes                  # Send email when begin/end/suspend
#$ -pe omp 4               # Request 4 cores

module load python3

cd analysis/structural
python make_start.py

