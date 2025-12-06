#!/bin/bash
# GAAIN Pipeline - Using your actual file structure

echo "=== GAAIN PIPELINE ==="
echo "Using files in data/ directory"
echo "==============================="

MNI_TEMPLATE="$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz"

# Process AD01
echo ""
echo "=== PROCESSING AD01 ==="

# 1. Brain extraction
echo "1. Brain extraction..."
bet data/AD01/anat/AD01_MR.nii \
    data/AD01/anat/AD01_MR_brain.nii.gz \
    -f 0.3 -B -R

# 2. T1 → MNI
echo "2. T1 to MNI normalization..."
flirt -in data/AD01/anat/AD01_MR_brain.nii.gz \
      -ref $MNI_TEMPLATE \
      -out data/AD01/anat/AD01_MR_MNI.nii.gz \
      -omat data/AD01/transform/T1_to_MNI.mat \
      -dof 12

# 3. PET → T1 coregistration
echo "3. PET to T1 coregistration..."
flirt -in data/AD01/pet/AD01_PiB_5070.nii \
      -ref data/AD01/anat/AD01_MR_brain.nii.gz \
      -out data/AD01/pet/AD01_PiB_5070_T1.nii.gz \
      -omat data/AD01/transform/PET_to_T1.mat \
      -dof 6 -cost mutualinfo

# 4. PET → MNI
echo "4. PET to MNI normalization..."
convert_xfm -omat data/AD01/transform/PET_to_MNI.mat \
            -concat data/AD01/transform/T1_to_MNI.mat \
                    data/AD01/transform/PET_to_T1.mat

flirt -in data/AD01/pet/AD01_PiB_5070.nii \
      -ref $MNI_TEMPLATE \
      -out data/AD01/pet/AD01_PiB_5070_MNI.nii.gz \
      -applyxfm -init data/AD01/transform/PET_to_MNI.mat

# 5. Threshold
echo "5. Applying threshold (0.001)..."
fslmaths data/AD01/pet/AD01_PiB_5070_MNI.nii.gz \
         -thr 0.001 data/AD01/pet/AD01_PiB_5070_MNI_thr.nii.gz

echo "=== AD01 PROCESSING COMPLETE ==="

# Process YC101 (optional)
echo ""
echo "=== PROCESSING YC101 ==="
bet data/YC101/anat/YC101_MR.nii \
    data/YC101/anat/YC101_MR_brain.nii.gz \
    -f 0.3 -B -R

flirt -in data/YC101/anat/YC101_MR_brain.nii.gz \
      -ref $MNI_TEMPLATE \
      -out data/YC101/anat/YC101_MR_MNI.nii.gz \
      -omat data/YC101/transform/T1_to_MNI.mat \
      -dof 12

flirt -in data/YC101/pet/YC101_PiB_5070.nii \
      -ref data/YC101/anat/YC101_MR_brain.nii.gz \
      -out data/YC101/pet/YC101_PiB_5070_T1.nii.gz \
      -omat data/YC101/transform/PET_to_T1.mat \
      -dof 6 -cost mutualinfo

convert_xfm -omat data/YC101/transform/PET_to_MNI.mat \
            -concat data/YC101/transform/T1_to_MNI.mat \
                    data/YC101/transform/PET_to_T1.mat

flirt -in data/YC101/pet/YC101_PiB_5070.nii \
      -ref $MNI_TEMPLATE \
      -out data/YC101/pet/YC101_PiB_5070_MNI.nii.gz \
      -applyxfm -init data/YC101/transform/PET_to_MNI.mat

fslmaths data/YC101/pet/YC101_PiB_5070_MNI.nii.gz \
         -thr 0.001 data/YC101/pet/YC101_PiB_5070_MNI_thr.nii.gz

echo "=== YC101 PROCESSING COMPLETE ==="
echo ""
echo "==============================="
echo "Pipeline complete!"
echo "Output in data/AD01/pet/AD01_PiB_5070_MNI_thr.nii.gz"
echo "==============================="
