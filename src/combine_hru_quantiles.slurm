#!/bin/bash
#SBATCH --job-name=combine_quantiles     # name that you chose
#SBATCH -c 1                            # number of cores per task
#SBATCH -p UV,normal              # choose both partitions
#SBATCH -A iidd                        # your account
#SBATCH --time=12:00:00        # time at which the process will be cancelled if unfinished
#SBATCH --mem=200G
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mhines@usgs.gov
#SBATCH -o /logs/%A_%a-%j.log            # log file for each jobid (can insert %A_%a for each array id task if needed)
#SBATCH --export=ALL

mkdir -p /lustre/projects/water/iidd/mhines/logs

module load R/3.5.1-gcc7.1.0

srun Rscript /lustre/projects/water/iidd/mhines/combine_hru_quantiles_david.R