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

maskfilter ${MASK_DIR}/brainmask.nii dilate ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_brainmask.mif

dwi2fod msmt_csd \
	-nthreads 2 \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_DWI.mif \
	$RESPONSE_DIR/group_average_response_wm.txt \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD.mif \
	$RESPONSE_DIR/group_average_response_gm.txt \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_GM.mif \
	$RESPONSE_DIR/group_average_response_csf.txt \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_CSF.mif \
	-mask ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_brainmask.mif
	
mtnormalise \
	-nthreads 2 \
  	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD_norm.mif \
  	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_GM.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_GM_norm.mif \
  	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_CSF.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_CSF_norm.mif \
  	-mask ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_brainmask.mif

rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD.mif
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_GM.mif
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_CSF.mif
  	
mrconvert \
	-coord 3 0 ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD_norm.mif - | \
	mrcat ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_CSF_norm.mif \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_GM_norm.mif \
	- ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_vf_norm.mif

tckgen ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD_norm.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_10M_prob.tck \
  	-algorithm iFOD2 \
  	-seed_dynamic ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD_norm.mif \
  	-output_seeds ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_seeds.txt \
  	-act ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_coreg.mif \
  	-backtrack \
  	-crop_at_gmwmi \
  	-maxlength 250 \
  	-minlength 20 \
  	-select 10M \
  	-nthreads 2 \
  	-cutoff 0.06


