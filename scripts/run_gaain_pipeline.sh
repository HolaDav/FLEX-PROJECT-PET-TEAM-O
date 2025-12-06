#!/bin/bash
# GAAIN Centiloid Pipeline in FSL - Using actual GAAIN filenames

echo "========================================"
echo "GAAIN Centiloid Pipeline - FSL Version"
echo "Using actual GAAIN filenames"
echo "========================================"

# Configuration
MNI_TEMPLATE="$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz"

# Function to process one subject
process_subject() {
    local SUBJ_DIR=$1  # e.g., AD01 or YC101
    local SUBJ_ID=$2   # e.g., AD01 or YC101
    
    echo ""
    echo "=== Processing $SUBJ_ID ==="
    
    # Check files exist
    if [ ! -f "$SUBJ_DIR/anat/${SUBJ_ID}_MR.nii" ] && [ ! -f "$SUBJ_DIR/anat/${SUBJ_ID}_MR.nii.gz" ]; then
        echo "ERROR: T1 not found for $SUBJ_ID"
        return 1
    fi
    
    # Unzip if needed
    if [ -f "$SUBJ_DIR/anat/${SUBJ_ID}_MR.nii.gz" ]; then
        gunzip -f "$SUBJ_DIR/anat/${SUBJ_ID}_MR.nii.gz"
    fi
    if [ -f "$SUBJ_DIR/pet/${SUBJ_ID}_PiB_5070.nii.gz" ]; then
        gunzip -f "$SUBJ_DIR/pet/${SUBJ_ID}_PiB_5070.nii.gz"
    fi
    
    # 1. Brain extraction (T1)
    echo "1. Brain extraction..."
    bet "$SUBJ_DIR/anat/${SUBJ_ID}_MR.nii" \
        "$SUBJ_DIR/anat/${SUBJ_ID}_MR_brain.nii.gz" \
        -f 0.3 -B -R
    
    # 2. T1 → MNI normalization
    echo "2. T1 to MNI normalization..."
    flirt -in "$SUBJ_DIR/anat/${SUBJ_ID}_MR_brain.nii.gz" \
          -ref $MNI_TEMPLATE \
          -out "$SUBJ_DIR/anat/${SUBJ_ID}_MR_MNI.nii.gz" \
          -omat "$SUBJ_DIR/transform/T1_to_MNI.mat" \
          -dof 12 \
          -searchrx -30 30 -searchry -30 30 -searchrz -30 30
    
    # 3. PET → T1 coregistration
    echo "3. PET to T1 coregistration..."
    flirt -in "$SUBJ_DIR/pet/${SUBJ_ID}_PiB_5070.nii" \
          -ref "$SUBJ_DIR/anat/${SUBJ_ID}_MR_brain.nii.gz" \
          -out "$SUBJ_DIR/pet/${SUBJ_ID}_PiB_5070_T1.nii.gz" \
          -omat "$SUBJ_DIR/transform/PET_to_T1.mat" \
          -dof 6 -cost mutualinfo
    
    # 4. Apply both transforms to get PET in MNI space
    echo "4. PET to MNI normalization..."
    convert_xfm -omat "$SUBJ_DIR/transform/PET_to_MNI.mat" \
                -concat "$SUBJ_DIR/transform/T1_to_MNI.mat" \
                        "$SUBJ_DIR/transform/PET_to_T1.mat"
    
    flirt -in "$SUBJ_DIR/pet/${SUBJ_ID}_PiB_5070.nii" \
          -ref $MNI_TEMPLATE \
          -out "$SUBJ_DIR/pet/${SUBJ_ID}_PiB_5070_MNI.nii.gz" \
          -applyxfm -init "$SUBJ_DIR/transform/PET_to_MNI.mat"
    
    # 5. Apply intensity threshold (0.001 as per GAAIN)
    echo "5. Applying intensity threshold (0.001)..."
    fslmaths "$SUBJ_DIR/pet/${SUBJ_ID}_PiB_5070_MNI.nii.gz" \
             -thr 0.001 "$SUBJ_DIR/pet/${SUBJ_ID}_PiB_5070_MNI_thr.nii.gz"
    
    echo "=== $SUBJ_ID processing complete ==="
}

# Process subjects
process_subject "AD01" "AD01"
process_subject "YC101" "YC101"

echo ""
echo "========================================"
echo "Preprocessing complete!"
echo "========================================"
