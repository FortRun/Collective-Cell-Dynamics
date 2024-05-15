This directory contains scripts for phase space exploration by varying paremeters X and Y using Runman(https://github.com/SomajitDey/runman).
Here we sketch out a possible workflow.
- Create a mother directory, say MD and change to it.
- Put run.sh and array.job inside MD.
- Make run.sh executable (chmod +x ./run.sh).
- Put the parameters common to all the runs, i.e. constant throughout phase space, inside common_params.in within MD.  
- Fill out / edit Xpoints, Ypoints, ncpu and wclock in array.job.
- Fill out Xpoints, Ypoints, paramX_beg, paramY_beg, paramX_stride and paramY_stride in run.sh.
- Edit the business logic in run.sh as necessary.
- Create a README or about.txt inside MD that documents all the details regarding the runs like
	* identification and range of the variable parameters
	* run protocol (pre-production > production), how many steps in each run etc.
	* syntax of individual run sub-directory names. E.g. one may use the integer pair <Xindex>_<YIndex>.
- When Runman launches the job, each instance of run.sh would create its own subdirectory <Xindex>_<YIndex> inside MD.
- Launch with : runman sub array.job
