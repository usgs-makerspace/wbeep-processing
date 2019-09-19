#!/bin/bash
#SBATCH --job-name=combine_quantiles     # name that you chose
#SBATCH -c 1                   # number of cores per task
#SBATCH -p normal              # the partition you want to use, for this case prod is best
#SBATCH -A iidd                 # your account
#SBATCH --time=05:00:00        # time at which the process will be cancelled if unfinished
#SBATCH --mem=120GB
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lplatt@usgs.gov
#SBATCH --export=ALL
#SBATCH --array=0 # don't need this to be parallel

mkdir -p logs

Rscript --verbose -e  'source("combine_hru_quantiles.R")' > logs/${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.Rlog 2>&1
