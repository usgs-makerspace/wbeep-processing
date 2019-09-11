#!/bin/bash
#SBATCH --job-name=read_and_reformat_historic     # name that you chose
#SBATCH -c 1                   # number of cores per task
#SBATCH -p normal              # the partition you want to use, for this case prod is best
#SBATCH -A iidd                # your account
#SBATCH --time=01:00:00        # time at which the process will be cancelled if unfinished
#SBATCH --mem=120GB
#SBATCH --mail-type=ALL
#SBATCH --mail-user=lplatt@usgs.gov
#SBATCH --export=ALL
#SBATCH --array=1,6            # Number of variables

mkdir -p logs

module load R/3.5.1-gcc7.1.0

Rscript --verbose -e  'source("reformat_ncdf_rds.R"); reformat_ncdf_rds()' > logs/${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.Rlog 2>&1
