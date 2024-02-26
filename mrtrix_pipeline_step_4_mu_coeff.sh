#!/bin/bash

# NeurArchCon Diffusion Script

SUBJECT=$1
root_dir=$2
FREESURFER_DIR=$root_dir/BIDS/derivatives/freesurfer/sub-${SUBJECT}
MRTRIX3_DIR=$root_dir/BIDS/derivatives/mrtrix3
OUTPUT_DIR=$MRTRIX3_DIR/sub-${SUBJECT}
CFIN_DIR=${root_dir}/BIDS/derivatives/CFINpipeline
MASK_DIR="${CFIN_DIR}/masksCA18106_DWI_CFINpipeline/${SUBJECT}/*/MR/KURTOSIS1/NATSPACE"
RESPONSE_DIR=$root_dir/BIDS/derivatives/mrtrix3/average_response
T1_DIR=$root_dir/BIDS/sub-${SUBJECT}/anat
SCRATCH=$root_dir/BIDS/derivatives/5tt

tcksift2 -act $OUTPUT_DIR/sub-${SUBJECT}_run-01_5tt.mif \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_10M_prob.tck \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD_norm.mif \
  	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_10M_prob.sift_second_run \
  	-out_mu ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_10M_prob.mu \
  	-out_coeffs ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_10M_prob.coeff
