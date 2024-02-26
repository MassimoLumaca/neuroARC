#!/bin/bash

# NeurArchCon Diffusion Script - note that this picks up from the CFIN pipeline

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

# Script for processing CFIN pipeline output with MRtrix3 for tractography


mkdir -p ${OUTPUT_DIR}

mrcat ${CFIN_DIR}/dataCA18106_DWI_CFINpipeline/${SUBJECT}/*/MR/KURTOSIS1_DIRS/NATSPACE/*nii ${OUTPUT_DIR}/temp.mif

mrconvert \
	${OUTPUT_DIR}/temp.mif \
	-fslgrad \
	${CFIN_DIR}/infoCA18106_DWI_CFINpipeline/${SUBJECT}/*/MR/KURTOSIS1/diffusion.bvec \
	${CFIN_DIR}/infoCA18106_DWI_CFINpipeline/${SUBJECT}/*/MR/KURTOSIS1/diffusion.bval \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_DWI.mif
	
rm ${OUTPUT_DIR}/temp.mif

# Create 5tt image for ACT 
5ttgen hsvs ${FREESURFER_DIR} ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt.mif -scratch ${SCRATCH}/sub-${SUBJECT} -nocleanup

# Co-register T1w to B0
dwiextract ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_DWI.mif - -bzero | \
	mrmath - mean ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0.nii.gz -axis 3

bet ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0.nii.gz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz
# mrconvert -strides -1,2,3 ${FREESURFER_DIR}/mri/norm.mgz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz

mri_vol2vol --mov ${FREESURFER_DIR}/mri/brain.mgz --targ ${FREESURFER_DIR}/mri/rawavg.mgz --regheader --o ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.mgz --no-save-reg
mri_vol2vol --mov ${FREESURFER_DIR}/mri/T1.mgz --targ ${FREESURFER_DIR}/mri/rawavg.mgz --regheader --o ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w.mgz --no-save-reg
# mri_label2vol --seg ${FREESURFER_DIR}/mri/wm.seg.mgz --temp ${FREESURFER_DIR}/mri/rawavg.mgz --o ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg.mgz --regheader ${FREESURFER_DIR}/mri/wm.seg.mgz
 
mri_convert -it mgz -ot nii ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.mgz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz
mri_convert -it mgz -ot nii ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w.mgz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w.nii.gz
# mri_convert -it mgz -ot nii ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg.mgz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg.nii.gz

rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.mgz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w.mgz
# rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg.mgz

fast ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz
mv ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_2.nii.gz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_0.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_1.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_mixeltype.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pveseg.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_seg.nii.gz


flirt -in ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz \
	-ref ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
	-dof 6 \
	-omat ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_initial.mat

flirt -in ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz \
	-ref ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
	-dof 6 \
	-cost bbr \
	-wmseg ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg.nii.gz \
	-init ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_initial.mat \
	-omat ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_bbr.mat \
	-schedule $FSLDIR/etc/flirtsch/bbr.sch
	
transformconvert ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_bbr.mat \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
	flirt_import ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_mrtrix_bbr.txt
	
mrtransform ${T1_DIR}/sub-${SUBJECT}_run-01_T1w.nii.gz \
	-linear ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_mrtrix_bbr.txt \
	-inverse ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_coreg.mif
	
mrtransform ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt.mif \
	-linear ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_mrtrix_bbr.txt \
	-inverse ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_coreg.mif
	
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w*.nii.gz
	
# Create 5tt visualisations for QC
5tt2vis ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_vis.mif	
5tt2vis ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_coreg.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_vis_coreg.mif

dwi2response dhollander \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_DWI.mif \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_RF_WM.txt \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_RF_GM.txt \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_RF_CSF.txt \
	-voxels ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_RF_voxels.mif
