#!/bin/bash -l

#$ -l h_rt=01:00:00               # Specify the hard time limit for the job
#$ -N structural_end              # Give job a name
#$ -j y                           # Merge the error and output streams into a single file
#$ -m bes                         # Send email when begin/end/suspend
#$ -pe omp 4                      # Request 4 cores

module load python3
module load matlab
cd setup
python -m pip install --user -r requirements.txt
python -m pip install --user -r setup_python.txt
cd ../analysis/structural

python make_end.py

