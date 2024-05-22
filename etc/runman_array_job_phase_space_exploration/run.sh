#!/usr/bin/env bash
# This sample script contains workflow for a single run with certain input parameters 
## for probing the phase space by varying parameters X and Y.
 
Xpoints= # Total number of paramX points
Ypoints= # Total number of paramY points

# RUNMAN_ARRAY_INDEX varies from 0 to Xpoints * Ypoints - 1 (see array.job)
# Resolve/Unpack RUNMAN_ARRAY_INDEX into integer pair [Xindex,Yindex] such that 
## RUNMAN_ARRAY_INDEX=Xindex*Ypoints + Yindex
Xindex=$((RUNMAN_ARRAY_INDEX / Ypoints))
Yindex=$((RUNMAN_ARRAY_INDEX % Ypoints))

# Beginning/Initial values for parameters X and Y as well as their strides
paramX_beg=
paramY_beg=
paramX_stride=
paramY_stride=

# Values of parameters X and Y for the current run
paramX=$(echo "${paramX_beg} + ${paramX_stride}*${Xindex}" | bc -l)
paramY=$(echo "${paramY_beg} + ${paramY_stride}*${Yindex}" | bc -l)

# Path to input parameters file containing the parameters constant throughout the phase space
export CCD_PARAMS_PATH="${PWD}/common_params.in"

# Create and change to own sub-directory that shall contain the run results
rundir="${Xindex}_${Yindex}"
mkdir -p "${rundir}"
cd "${rundir}"

# Redirect stdout and stderr to specific log files within rundir
exec > stdout.log 2> stderr.log

########## Business logic ############

# Preparation / Preproduction run followed by initialization
ccd -p "X=${paramX}" -p "Y=${paramY}" init
ccd -p "X=${paramX}" -p "Y=${paramY}" -p "nsteps=<>" run

# Production run
ccd -p "X=${paramX}" -p "Y=${paramY}" -p "nsteps=<>" run
