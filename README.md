# README

## Data and Code Availability Statement

### Data

There are two sources of data for this study, both of which are available in `/raw` from [openICPSR](https://doi.org/10.3886/E125682V1):

1. Trip-level records on cab fares from the New York City (NYC) Taxi and Limousine Commission.

2. Minute-level weather conditions collected at five locations around NYC from the National Centers for Environmental Information.

If the `/raw` folder is not yet populated, please add the folder from the [openICPSR](https://doi.org/10.3886/E125682V1) link to the root of the replication package.

### Code

The replication files can be run by following the instructions in the **Instructions for Data Preparation and Analysis** section of this README.

The replication files to obtain the results in the paper consist of three steps.

- In the first step, all original raw data are processed to prepare the data for analysis.
- In the second step, the results in Section III of the paper are obtained.
- In the third step, the results in Sections I and II of the paper are obtained.

All code files for all three steps are provided in this replication package. This includes `.sh` scripts which indicate the computational and runtime requirements for each step and facilitate running the analyses from the second step in parallel.

Support by the authors for replication is provided if necessary.

For reference, the code files used in each step can be found from the following files:

- `run_data.py` (first step);
- `analysis/structural/make_table3.py`, `analysis/structural/make_table4_col134.py`, `analysis/structural/make_table4_col2.py`, `analysis/structural/make_table4_col5.py`, `analysis/structural/make_appendixtables.py`, and `analysis/structural/make_end.py` (second step);
- and `run_reduced_form.py` (third step).

Files of the form `run_*.py` contain a list of modules which refer to directories within the replication package, and the `make.py` file within each such directory contains a list of code files that will be run when that module is called. The list of code files in each file of the form `make*.py` can be found immediately following the line that says

   ```python
   ### RUN SCRIPTS
   ```

### Output

All figures (in `.pdf` or `.png` format) and tables (in `.txt` format) that appear in the paper and online appendix can be found in `analysis/*/output/`.

## Computational Requirements

Computational requirements (hardware, software, additional packages, and wall-clock time) are specified in the `.sh` files referenced in the **Instructions for Data Preparation and Analysis** section of this README. See below for further details.

### Computer hardware

All files were last run on the Boston University Shared Computing Cluster (SCC). The system currently includes over 8,000 shared CPU cores and 6 petabytes of storage. Shared nodes contain at least 48 GB and up to 1024 GB of memory; at least 152 GB and up to 1068 GB of scratch disk space per node; and either 1 eight-core 2.1 GHz Intel Xeon E5-2620v4 processor, 1 sixtyeight-core 1.4 GHz Intel Xeon Phi (Knights Landing) 7250 processor, 1 twelve-core 2.4 GHz Intel Xeon E5-2620v3 processor, 2 eight-core 2.6 GHz Intel Xeon E5-2650v2 processors, 2 eight-core 2.6 GHz Intel Xeon E5-2670 processors, 2 eighteen-core 2.4 GHz Intel Xeon E7-8867v4 processors, 2 fourteen-core 2.4 GHz Intel Xeon E5-2680v4  processors, 2 fourteen-core 2.6 GHz Intel Gold 6132 processors, 2 six-core 3.07 GHz Intel Xeon X5675 processors, or 2 ten-core 2.6 GHz Intel Xeon E5-2660v3 processors.

The Sun Grid Engine (SGE) queuing system allows a job to request specific SCC resources necessary for a successful run, including a node with large memory, multiple CPUs, a specific queue, or a node with a specific architecture. This is the system called by the `.sh` files and therefore is required to use these scripts.

Non-interactive batch jobs are submitted with the `qsub` command. When running a program that requires arguments and passes additional options to the batch system, it quickly becomes useful to save them in a script file and submit this script as an argument to the `qsub` command. To submit a file script.sh to the batch system, execute `qsub script.sh`. We provide these batch files as part of this replication package.

Running this replication package makes use of 300 GB of disk space, 28 cores, and 192 GB of memory.

### Software

The `module` package is used to access tools or versions of standard packages. Specific modules can be loaded and unloaded as required. The module command is provided by the `Lmod` software which is developed at the Texas Advanced Computing Center.

The following `module load` commands are called in the `.sh` files referenced in the **Instructions for Data Preparation and Analysis** section of this README to enable the softwares used. These modules should have the exact same names and should refer to the correct versions (see below), or these lines in the `.sh` files will have to be modified by the user.

- `module load matlab`
- `module load python3`
- `module load R`
- `module load stata-mp`

The exact software used in this replication package are as below:

- matlab/2020a
- python3/3.8.3
- R/4.0.0
- stata-mp/16
- pip (>=10.0)

#### Command Line Usage

By default, the replication scripts assume the following executable names for the following applications:

   ```text
   application : executable
   python      : python
   r           : Rscript
   stata       : stata-mp
   matlab      : matlab
   ```

Default executable names can be updated in `config_user.yaml` below the following lines:

   ```text
   local:

   # Executable names
   executables:
   ```

### Additional packages

When the `.sh` files are run by following the instructions in the **Instructions for Data Preparation and Analysis** section of this README, all necessary additional packages for Python, Stata, and R are automatically installed.

For reference, dependencies for Python code can be found in the `setup/requirements.txt` and `setup/setup_python.txt` files, dependencies for Stata code can be found in the `setup_stata.do` file, and dependencies for R code can be found in the `setup/setup_r.R` file.

### Wall-clock time

The `-l h_rt=hh:mm:ss` lines of the `.sh` files referenced in the **Instructions for Data Preparation and Analysis** section of this README contain the runtime allowances.

The amount of time taken in practice may depend on the computing environment, e.g., which processor is used. In practice, the amount of time taken is as follows:

- First step: up to 40 hours
- Second step (parallelized): up to 7 hours
- Third step: up to 30 hours

## Instructions for Data Preparation and Analysis

The three steps below have to be done sequentially, with one step finishing before the next one starts. Use the command `qsub -u USERNAME` to see which scripts (belonging to user with username `USERNAME`) are still running and confirm that all scripts are complete before the next step.

### Data preparation

#### First step

Run the following bash command from the root directory of the replication package:

   ```shell
   qsub step1_data.sh
   ```

After the first step is complete, proceed to the second step.

### Analysis

#### Second step

The second step consists of three parts. The instructions for each part can be followed **once the previous part finishes running**.

1. Run the following bash command from the root directory of the replication package:

      ```shell
      qsub step2a_structural_start.sh
      ```

2. Once the above is complete as confirmed by using the command `qstat -u USERNAME`, run the following bash command from the root directory of the replication package:

      ```shell
      qsub step2b_structural_main.sh
      ```

   This command launches five scripts, each of which will in turn use the Sun Grid Engine to run 230 estimations in parallel.

3. Once all the parallel scripts above are complete as confirmed by using the command `qstat -u USERNAME`, run the following bash command from the root directory of the replication package:

      ```shell
      qsub step2c_structural_end.sh
      ```

After the second step is complete, proceed to the third step.

#### Third step

Run the following bash command from the root directory of the replication package:

   ```shell
   qsub step3_reduced_form.sh
   ```
