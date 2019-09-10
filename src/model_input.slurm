#!/bin/bash
#SBATCH --job-name=calculate_hru_percentiles     # name that you chose
#SBATCH -c 1                   # number of cores per task
#SBATCH -p normal              # the partition you want to use, for this case prod is best
#SBATCH -A iidd                 # your account
#SBATCH --time=01:00:00        # time at which the process will be cancelled if unfinished
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lplatt@usgs.gov
#SBATCH --export=ALL
#SBATCH --array=1-5 # eventually 1:4399 (109,952 HRUs / 25 HRUs per task = 4,399 tasks)

mkdir -p logs
mkdir -p quantiles_by_task

Rscript --verbose -e  'source("process_quantiles_by_hru.R"); calcuate_percentiles_by_hru()' > logs/${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.Rlog 2>&1
