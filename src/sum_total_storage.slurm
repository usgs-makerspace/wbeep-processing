#!/bin/bash
#SBATCH --job-name=sum_storage     # name that you chose
#SBATCH -c 8                            # number of cores per task
#SBATCH -p UV,normal              # choose both partitions
#SBATCH -A iidd                        # your account
#SBATCH --time=00:30:00        # time at which the process will be cancelled if unfinished
#SBATCH --mem=100GB
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mhines@usgs.gov
#SBATCH -o /logs/sum_storage.log            # log file for each jobid (can insert %A_%a for each array id task if needed)
#SBATCH --export=ALL

mkdir -p logs
mkdir -p grouped_total_storage

module load R/3.5.1-gcc7.1.0

srun Rscript src/sum_total_storage.R