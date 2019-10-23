#!/bin/bash
#SBATCH --job-name=process_quantiles     # name that you chose
#SBATCH -c 1                   # number of cores per task
#SBATCH -p UV,normal              # the partition you want to use, for this case prod is best
#SBATCH -A iidd                 # your account
#SBATCH --time=02:00:00        # time at which the process will be cancelled if unfinished
#SBATCH --mem=200G
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mhines@usgs.gov
#SBATCH -o /logs/%A_%a-%j.log            # log file for each jobid (can insert %A_%a for each array id task if needed)
#SBATCH --export=ALL
#SBATCH --array=1-110 # 109,951 HRUs / 1000 HRUs per task = 110 tasks

mkdir -p /lustre/projects/water/iidd/mhines/logs
mkdir -p /lustre/projects/water/iidd/mhines/grouped_quantiles

module load R/3.5.1-gcc7.1.0

srun Rscript /lustre/projects/water/iidd/mhines/process_quantiles.R
