#!/bin/bash
#SBATCH --job-name=split_out_data     # name that you chose
#SBATCH -c 1                   # number of cores per task
#SBATCH -p UV,normal              # the partition you want to use, for this case prod is best
#SBATCH -A iidd                 # your account
#SBATCH --time=03:00:00        # time at which the process will be cancelled if unfinished
#SBATCH --mem=120GB
#SBATCH --mail-type=ALL
#SBATCH -o /logs/%A_%a-%j.log            # log file for each jobid (can insert %A_%a for each array id task if needed)
#SBATCH --export=ALL
#SBATCH --array=1-6 # do this in parallel for each var

mkdir -p /lustre/projects/water/iidd/mhines/logs
mkdir -p /lustre/projects/water/iidd/mhines/cache

module load R/3.5.1-gcc7.1.0

srun Rscript /lustre/projects/water/iidd/mhines/split_historic_data.R
