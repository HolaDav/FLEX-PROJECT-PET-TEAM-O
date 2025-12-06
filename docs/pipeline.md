
# Pipeline Documentation
## Step-by-Step Protocol
### 1. Environment Setup

# Launch Neurodesk with FSL
# Set MNI template path
export MNI_TEMPLATE="/cvmfs/neurodesk.ardc.edu.au/containers/mrtrix3_3.0.1_20200908/mrtrix3_3.0.1_20200908.simg/opt/fsl-6.0.3/data/standard/MNI152_T1_2mm.nii.gz"

### 2. Preprocessing Pipeline
Each subject undergoes:

1. T1 skull-stripping: bet input.nii output_brain.nii.gz -f 0.3 -B -R

2. T1→MNI normalization: flirt -in T1_brain -ref MNI -out T1_MNI -omat T1_to_MNI.mat -dof 12

3. PET→T1 coregistration: flirt -in PET -ref T1_brain -out PET_T1 -omat PET_to_T1.mat -dof 6

4. PET→MNI normalization: Concatenate transforms and apply

5. Intensity thresholding: fslmaths PET_MNI -thr 0.001 PET_MNI_thr

### 3. VOI Processing

# Convert probability maps to binary
fslmaths voi_ctx_2mm.nii -thr 0.5 -bin voi_ctx_binary.nii
fslmaths voi_CerebGry_2mm.nii -thr 0.5 -bin voi_cereb_binary.nii

# Align to each subject
flirt -in MNI_template -ref subject_PET -out MNI_to_subject -omat MNI_to_subject.mat -dof 6
flirt -in voi_ctx_binary -ref subject_PET -out voi_ctx_subject -applyxfm -init MNI_to_subject.mat -interp nearestneighbour

### 4. SUVR Calculation

cortical=$(fslstats subject_PET -k voi_ctx_subject -M)
cerebellar=$(fslstats subject_PET -k voi_cereb_subject -M)
suvr=$(echo "$cortical / $cerebellar" | bc -l)

### 5. Quality Control

Cerebellar mean should be 1-4

Validate with AD01 published value (2.524)

Exclude outliers (cerebellar > 10)
