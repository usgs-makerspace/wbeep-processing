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

1. Load data and scripts onto Yeti (yeti.cr.usgs.gov, AD login). Include all 6 model component historic record files, `combine_historic_records.R`, `model_input.slurm`, `process_quantiles_by_hru.R`, and `combine_hru_quantiles.R`. Lindsay used WinSCP to do this step.
2. Login to Yeti, `ssh user@yeti.cr.usgs.gov`
3. Start interactive session `sinteractive -A iidd -p normal -n 1 -t 03:00:00  --mem=120GB` & start R, by entering `R`.
4. Run `source("combine_historic_records.R")` to combine the data into one file. This step took about 20 minutes. Close R using `q()` and don't save the workspace image.
5. When that is finished, kick off the parallel job `sbatch model_input.slurm`. If you are a windows user, you may need to run `dos2unix model_input.slurm` first to make the line endings correct.
6. When that is complete, start an interactive session just as before and run `source("combine_hru_quantiles.R")`

That should be everything! The resulting quantiles RDS file should be available in the appropriate S3 bucket.
