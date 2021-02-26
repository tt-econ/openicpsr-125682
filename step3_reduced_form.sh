#!/bin/bash -l

#$ -l h_rt=40:00:00        # Specify the hard time limit for the job
#$ -N reduced_form         # Give job a name
#$ -j y                    # Merge the error and output streams into a single file
#$ -m bes                  # Send email when begin/end/suspend
#$ -pe omp 28              # Request 28 cores

module load python3
cd setup
python -m pip install --user -r requirements.txt
module load stata-mp
stata-mp -e setup_stata.do
Rscript setup_r.R
cd ..

python run_reduced_form.py

