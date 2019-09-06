#!/bin/bash
#SBATCH --job-name=calculate_hru_percentiles     # name that you chose
#SBATCH -c 1                   # number of cores per task
#SBATCH -p normal              # the partition you want to use, for this case prod is best
#SBATCH -A cida                 # your account
#SBATCH --time=01:00:00        # time at which the process will be cancelled if unfinished
#SBATCH -o logs/%A_%a.log  # sets output log file to array_job.log
#SBATCH --mail-type=ALL
#SBATCH --mail-user=wwatkins@usgs.gov
#SBATCH --export=ALL
#SBATCH --array=51,148,401,598

Rscript --verbose -e  'source("src/process_model_input.R"); calcuate_percentiles_by_hru(NA)' > logs/${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.Rlog 2>&1
