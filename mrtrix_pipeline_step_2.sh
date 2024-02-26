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

mkdir ${RESPONSE_DIR}

responsemean ${MRTRIX3_DIR}/sub-*/sub-*_run-01_RF_WM.txt $RESPONSE_DIR/group_average_response_wm.txt
responsemean ${MRTRIX3_DIR}/sub-*/sub-*_run-01_RF_GM.txt $RESPONSE_DIR/group_average_response_gm.txt
responsemean ${MRTRIX3_DIR}/sub-*/sub-*_run-01_RF_CSF.txt $RESPONSE_DIR/group_average_response_csf.txt
