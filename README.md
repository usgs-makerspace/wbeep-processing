# wbeep-processing
the processing behind the wbeep viz

## Building a release

There are four Jenkins jobs chained together, in this order:

`HRU to GeoJSON -> Tippecanoe tile creation -> model output processing -> tile join`

To build a release, cut the release in this repository with an appropriate vx.x.x tag.  Go to the `HRU to GeoJSON` job, and start it with the appropriate tier and tag.  The tag list should populate automatically.  The tier and tag will be passed along to the downstream jobs.  

For non-release changes to test that only affect downstream jobs, you can start the appropriate job and will pass the parameters downstream the same way.  

The `HRU to GeoJSON -> Tippecanoe tile creation` part of the pipeline can run parallel to the model output processing job in terms of dependencies; the pipeline is linear for now in the interest of making the Jenkins jobs simpler.  

## Building the percentiles

This happens very infrequently, so we currently have it as a manual step running on Yeti. Follow the steps below to execute.

#### First, setup Yeti for these calculations.

Load data and scripts onto Yeti (yeti.cr.usgs.gov, AD login). Include all 6 model component historic record files with the pattern `historical_[var name]_out.nc`). Also load all scripts needed (see list below). Lindsay used WinSCP to do this step. It took a long time (hours!). If Lindsay or Megan still have the files in their user account (/home/lplatt or /home/mhines) you can just copy the files to your own home dir from within one of those directories with `cp *.R /home/<yourhomedir>` and `cp *.slurm /home/<yourhomedir>` and `cp *.nc /home/<yourhomedir>`

Ideally, rather than working in your home dir, email Natalya Rapstine (nrapstine@usgs.gov) to set up workspace in the Lustre storage area (/lustre/projects/water/iidd/mhines for example), since the home dir is a limited resource.

* `split_historic_data.R`, 
* `split_historic_data.slurm`, 
* `process_quantiles_by_hru.R`, 
* `process_quantiles_by_hru.slurm`
* `combine_hru_quantiles.R`, and
* `combine_hru_quantiles.slurm`.

#### Now, execute the steps on Yeti.

1. Login to Yeti, `ssh user@yeti.cr.usgs.gov`
1. If you are a windows user, you may need to run `dos2unix split_historic_data.slurm` before continuing to make the line endings correct for each of the `.slurm` files before using them.
1. Enter the R environment and install needed R packages for all the R scripts. You will need: ncdf4, dplyr, purrr and tidyr. Type `R` at the command prompt and then `install.packages(c("ncdf4","dplyr","purrr","tidyr","pryr","data.table"))` and <enter> once you're in the environment. When it is installing it'll ask if you want to create a personal libraries to put these packages, type `yes` to create a personal library, pick a CRAN mirror, and ensure that the package installs. To quit R, type `q()`, and choose whether or not to save the session.
1. Edit each *.slurm script to include your email adress and your account information, otherwise you will see an error `sbatch: error: Batch job submission failed: Invalid account or account/partition combination specified`
1. First we need to read and reformat the variable NetCDF files and then split into a file for each HRU for each variable. To do so, run `sbatch split_historic_data.slurm`. You should see a `cache` folder, which will have 659,706 small RDS files when complete. You can manually monitor progress by counting how many files are currently in the folder by running `ls -1 cache | wc -l`. This process took about 2 hours for all tasks to finish on 9/13/2019.
1. When the step to split the historic data is complete, you can kick off the job that processes the percentiles by running `sbatch process_quantiles_by_hru.slurm`. You can monitor their progress by running `squeue -u [username]`. THIS IS EXTREMELY SLOW. Haven't run the full thing, but would take 12 hours by my estimate. Sometimes it would still run out of memory (maybe I should use `for` instead of `lapply`?) so I would just have to kick it off again. It skips files that already exist, so it gets to move forward, just kind of annoying. To monitor progress as it goes, you can run `ls -1 quantiles_by_hru | wc -l` to see how many files are in the folder. There should be 109,951.
1. When that is complete, you can kick off the final process which will combine all of HRU files into one quantiles file called `all_quantiles-[date].rds`. To start, execute `sbatch combine_hru_quantiles.slurm`.

That should be everything! The resulting quantiles RDS file will need to be manually uploaded to the appropriate S3 bucket. You can now delete the files on your Yeti root directory (and you should to free up space).
