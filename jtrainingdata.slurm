#!/bin/bash
#SBATCH --job-name=gendata       # create a short name for your job
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=1        # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mem-per-cpu=4G         # memory per cpu-core (4G per cpu-core is default)
#SBATCH --time=00:10:00          # total run time limit (HH:MM:SS)

module purge
module load matlab/R2019b

matlab -batch training_data_script
