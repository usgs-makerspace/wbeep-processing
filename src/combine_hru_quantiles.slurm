#!/bin/bash
#SBATCH --job-name=combine_quantiles     # name that you chose
#SBATCH -c 1                            # number of cores per task
#SBATCH -p UV,normal              # choose both partitions
#SBATCH -A iidd                        # your account
#SBATCH --time=00:30:00        # time at which the process will be cancelled if unfinished
#SBATCH --mem=32GB
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mhines@usgs.gov
#SBATCH -o logs/slurm_combine.out            # log file for each jobid (can insert %A_%a for each array id task if needed)
#SBATCH --export=ALL

module load R/3.5.1-gcc7.1.0

srun Rscript src/combine_hru_quantiles.R
