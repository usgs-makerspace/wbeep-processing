#!/bin/bash
#SBATCH --job-name=process_quantiles     # name that you chose
#SBATCH -p normal,UV              # the partition you want to use, for this case prod is best
#SBATCH -c 8
#SBATCH -A iidd                 # your account
#SBATCH -o logs/slurm-%A_%a-%j.out
#SBATCH --time=00:50:00        # time at which the process will be cancelled if unfinished
#SBATCH --mem=80GB
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mhines@usgs.gov
#SBATCH --export=ALL
#SBATCH --array=1-110 # 109,951 HRUs / 1000 HRUs per task = 110 tasks

mkdir logs
mkdir grouped_quantiles

module load R/3.5.1-gcc7.1.0

srun Rscript src/process_quantiles.R
