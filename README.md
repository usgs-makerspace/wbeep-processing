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

Load data and scripts onto Yeti (yeti.cr.usgs.gov, AD login). Include all 6 model component historic record files with the pattern `historical_[var name]_out.nc`). Also load all scripts needed (see list below). Lindsay used WinSCP to do this step. It took a long time (hours!). If Lindsay or Megan still have the files in their user account (/home/lplatt or /home/mhines) you can just copy the files to your own home dir from within one of those directories with `cp *.R /home/<yourhomedir>` and `cp *.slurm /home/<yourhomedir>` and `cp *.nc /home/<yourhomedir>`. Create a `src/` and `logs/` directory. Add the `.R` and `.slurm` files to the `src/` folder. 

Ideally, rather than working in your home dir, email Natalya Rapstine (nrapstine@usgs.gov) to set up workspace in the Lustre storage area (/lustre/projects/water/iidd/mhines for example), since the home dir is a limited resource.

* `sum_total_storage.R`, 
* `sum_total_storage.slurm`, 
* `process_quantiles.R`, 
* `process_quantiles.slurm`
* `combine_hru_quantiles.R`, and
* `combine_hru_quantiles.slurm`.

#### Now, execute the steps on Yeti.

1. Login to Yeti, `ssh user@yeti.cr.usgs.gov`
1. If you are a windows user, you may need to run `dos2unix src/sum_total_storage.slurm` before continuing to make the line endings correct for each of the `.slurm` files before using them.
1. Enter the R environment and install needed R packages for all the R scripts. You will need: ncdf4, feather, dplyr, purrr, tidyr, pryr, data.table. Type `R` at the command prompt and then `install.packages(c("ncdf4","feather","dplyr","purrr","tidyr","pryr","data.table"))` and <enter> once you're in the environment. When it is installing it'll ask if you want to create a personal libraries to put these packages, type `yes` to create a personal library, pick a CRAN mirror, and ensure that the package installs. To quit R, type `q()`, and choose whether or not to save the session.
1. Edit each *.slurm script to include your email adress and your account information, otherwise you will see an error `sbatch: error: Batch job submission failed: Invalid account or account/partition combination specified`
1. First we need to read and add up the variable NetCDF files and then split into a file for each group of HRUs. To do so, run `sbatch src/sum_total_storage.slurm`. You should see a `grouped_total_storage` folder, which will have 110 small RDS files when complete. You can manually monitor progress by counting how many files are currently in the folder by running `ls -1 grouped_total_storage | wc -l`. You can also use `sidle -u [user]` to see progress of any job. This process took about 20 minutes for 10,000 HRUs to finish on 10/25/2019. Amount of time to read in the NetCDF files varied (sometimes > 45 minutes). Lindsay ran this code for all 109K HRUs by running the script without the slurm job: `salloc -A iidd -p normal -n 8 -t 00:30:00`, starting `R`, and running `source("src/sum_total_storage.slurm")`. That only took ~ 10 minutes.
1. When the step to sum and split the historic data is complete, you can kick off the job that processes the percentiles by running `sbatch src/process_quantiles.slurm`. You can look at the messages coming from R by running `tail -f logs/[slurm out file name]`. To monitor progress as it goes, you can also run `ls -1 grouped_quantiles | wc -l` to see how many files are in the folder. There should be 110 by the end. This step took about 4 min per task but didn't do all of the tasks at once, so in the end it took about 20 minutes on 10/28/2019.
1. When that is complete, you can kick off the final process which will combine all of grouped HRU quantile files into one quantiles file called `all_quantiles.rds`. To start, execute `sbatch src/combine_hru_quantiles.slurm`. This step seems to be faster on Lindsay's computer.

That should be everything! The resulting quantiles RDS file will need to be manually uploaded to the appropriate S3 bucket. You can now delete the files on your Yeti root directory (and you should to free up space).

## Subsetting the historical NetCDF files to a single day

We are doing this to be able to troubleshoot the viz while the model is still running. I wanted to document how I did it in case we need to do it again in the future (or when we want to see what a different date looks like). The resulting files can be used as input to the `process_model_output.R` step.

1. Make sure you have the historic files. They are in the form `historical_[var]_out.nc`.
1. Login to Yeti, `ssh user@yeti.cr.usgs.gov`
1. Start a new interactive session using, `sinteractive -A iidd -p normal -n 1 -t 00:30:00`
1. Load the module to subset and save NetCDF files with `module load tools/nco-4.7.8-gnu`.
1. Identify which day you would like to use. For this example, I am using `2018-05-06`.
1. Figure out the appropriate NetCDF time index based on your chosen date: Start an R session by typing `R` and hitting enter. Then run the following code (it shouldn't matter which NetCDF file you use to figure this out). Take the resulting number and use it in to the `ncks` command in the next step. For `2018-05-06`, this value was `13731`. End the R session by running `q()`.

    ```
    library(ncdf4)
    nc <- nc_open("historical_soil_moist_tot_out.nc")
    time_att <- ncdf4::ncatt_get(nc, "time")
    time_start <- as.Date(gsub("days since ", "", time_att$units))
    as.numeric(as.Date("2018-05-06") - time_start)
    ```

1. Create the subsets by running the code below with your chosen day and the corresponding NetCDF index substituted where appropriate. For this example, the day is `2018-05-06` and the corresponding NetCDF time index is `4449`.

    ```
    vars='dprst_stor_hru soil_moist_tot hru_intcpstor pkwater_equiv hru_impervstor gwres_stor'
    for v in $vars; do
        f='historical_'$v'_out.nc'
        out_f='2018-05-06_'$v'.nc'
        ncks -d time,13731 $f $out_f
    done
    ```

You should now have a set of subset NetCDF files named with the appropriate date in your environment.


## Updating the Docker images

There are two docker images used in the processing steps --- one for R, and one for tippecanoe.  The built images are stored in the Docker registry at https://code.chs.usgs.gov/wma/iidd/wbeep-data-processing.  If you need to update the images, follow these steps:

1. Make the appropriate changes to the Dockerfile, and make sure it builds locally using `docker-compose build` while in the directory containing both the Dockerfile and docker-compose.yml.  

2. Make a pull request and have it reviewed.  

3. When the pull request is merged, it should trigger a Jenkins job that will build the image and push it to the docker registry tagged as `R-latest` or `tippecanoe-latest`.

### Docker image tagging

Note that as of November 2019, we are not storing different tags for each Docker image, since we have not needed to make substantial environment changes.  Each build of the images is tagged as `[R/tippecanoe]-latest` and overwrites the older tag when it is pushed to the registry.  All the processing jobs are hard-coded to use these tagged images.  To revert, we would need to make the change in the Github repo and rebuild the image using the image build Jenkins job.   

If in the future we want the ability to more easily switch between docker images, we may want to start tagging each image build uniquely with a version number, and then parameterize the docker image used in the data processing Jenkins jobs.  This would involve either using an automatically incrementing or manually set version number in the docker image build job, and adding an additional environment variable to all the processing jobs that sets the docker image used.   
