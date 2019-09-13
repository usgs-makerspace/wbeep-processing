#!/bin/bash
#SBATCH --job-name=calculate_hru_percentiles     # name that you chose
#SBATCH -c 1                   # number of cores per task
#SBATCH -p normal              # the partition you want to use, for this case prod is best
#SBATCH -A iidd                 # your account
#SBATCH --time=02:00:00        # time at which the process will be cancelled if unfinished
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lplatt@usgs.gov
#SBATCH --export=ALL
#SBATCH --array=1-50 # eventually 1:50 (109,951 HRUs / 50 tasks = 2200 HRUs per task)

mkdir -p logs
mkdir -p quantiles_by_hru

Rscript --verbose -e  'source("process_quantiles_by_hru.R")' > logs/${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.Rlog 2>&1
