#!/bin/bash
# Working GAAIN Pipeline with correct paths

echo "=== WORKING GAAIN PIPELINE ==="

# Find MNI template
if [ -f "$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz" ]; then
    MNI_TEMPLATE="$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz"
elif [ -f "$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz" ]; then
    MNI_TEMPLATE="$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz"
else
    echo "ERROR: Cannot find MNI template"
    exit 1
fi

echo "Using template: $MNI_TEMPLATE"

# Process AD01
echo ""
echo "=== PROCESSING AD01 ==="

# 1. Create transform directory
mkdir -p data/AD01/transform

# 2. Brain extraction
echo "1. Brain extraction..."
bet data/AD01/anat/AD01_MR.nii \
    data/AD01/anat/AD01_MR_brain.nii.gz \
    -f 0.3 -B -R

# 3. T1 → MNI
echo "2. T1 to MNI normalization..."
flirt -in data/AD01/anat/AD01_MR_brain.nii.gz \
      -ref $MNI_TEMPLATE \
      -out data/AD01/anat/AD01_MR_MNI.nii.gz \
      -omat data/AD01/transform/T1_to_MNI.mat \
      -dof 12

# 4. PET → T1 coregistration
echo "3. PET to T1 coregistration..."
flirt -in data/AD01/pet/AD01_PiB_5070.nii \
      -ref data/AD01/anat/AD01_MR_brain.nii.gz \
      -out data/AD01/pet/AD01_PiB_5070_T1.nii.gz \
      -omat data/AD01/transform/PET_to_T1.mat \
      -dof 6 -cost mutualinfo

# 5. PET → MNI
echo "4. PET to MNI normalization..."
convert_xfm -omat data/AD01/transform/PET_to_MNI.mat \
            -concat data/AD01/transform/T1_to_MNI.mat \
                    data/AD01/transform/PET_to_T1.mat

flirt -in data/AD01/pet/AD01_PiB_5070.nii \
      -ref $MNI_TEMPLATE \
      -out data/AD01/pet/AD01_PiB_5070_MNI.nii.gz \
      -applyxfm -init data/AD01/transform/PET_to_MNI.mat

# 6. Threshold
echo "5. Applying threshold (0.001)..."
fslmaths data/AD01/pet/AD01_PiB_5070_MNI.nii.gz \
         -thr 0.001 data/AD01/pet/AD01_PiB_5070_MNI_thr.nii.gz

echo "=== AD01 COMPLETE ==="
echo "Output: data/AD01/pet/AD01_PiB_5070_MNI_thr.nii.gz"
