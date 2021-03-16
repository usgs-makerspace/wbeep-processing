#!/bin/bash
#SBATCH --job-name=calc_max     # name that you chose
#SBATCH -c 8                            # number of cores per task, unsure on UV
#SBATCH -p UV,normal              # seems slow on normal to read in files
#SBATCH -A iidd                        # your account
#SBATCH --time=00:45:00        # time at which the process will be cancelled if unfinished
#SBATCH --mem=20GB
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mhines@usgs.gov
#SBATCH -o logs/slurm_calc_max.out            # log file for each jobid (can insert %A_%a for each array id task if needed)
#SBATCH --export=ALL

module load R/3.6.1
module load netcdf

srun Rscript src/calc_max.R
