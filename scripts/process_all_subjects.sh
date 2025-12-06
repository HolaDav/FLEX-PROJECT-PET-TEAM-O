#!/bin/bash
# Process multiple subjects

MNI_TEMPLATE="/cvmfs/neurodesk.ardc.edu.au/containers/mrtrix3_3.0.1_20200908/mrtrix3_3.0.1_20200908.simg/opt/fsl-6.0.3/data/standard/MNI152_T1_2mm.nii.gz"

echo "=== PROCESSING MULTIPLE SUBJECTS ==="

# List of subjects to process
SUBJECTS=("AD01" "AD02" "AD03" "AD04" "AD05" "YC101" "YC102" "YC103" "YC104" "YC105")

for SUBJECT in "${SUBJECTS[@]}"; do
    echo ""
    echo "=== Processing $SUBJECT ==="
    
    # Check if files exist
    T1_FILE=""
    PET_FILE=""
    
    # Find T1 file (could be .nii or .nii.gz)
    if [ -f "data/$SUBJECT/anat/${SUBJECT}_MR.nii" ]; then
        T1_FILE="data/$SUBJECT/anat/${SUBJECT}_MR.nii"
    elif [ -f "data/$SUBJECT/anat/${SUBJECT}_MR.nii.gz" ]; then
        T1_FILE="data/$SUBJECT/anat/${SUBJECT}_MR.nii.gz"
        # Unzip it
        gunzip -f "$T1_FILE"
        T1_FILE="data/$SUBJECT/anat/${SUBJECT}_MR.nii"
    fi
    
    # Find PET file
    if [ -f "data/$SUBJECT/pet/${SUBJECT}_PiB_5070.nii" ]; then
        PET_FILE="data/$SUBJECT/pet/${SUBJECT}_PiB_5070.nii"
    elif [ -f "data/$SUBJECT/pet/${SUBJECT}_PiB_5070.nii.gz" ]; then
        PET_FILE="data/$SUBJECT/pet/${SUBJECT}_PiB_5070.nii.gz"
        gunzip -f "$PET_FILE"
        PET_FILE="data/$SUBJECT/pet/${SUBJECT}_PiB_5070.nii"
    fi
    
    if [ -z "$T1_FILE" ] || [ -z "$PET_FILE" ]; then
        echo "  Skipping $SUBJECT - files not found"
        continue
    fi
    
    echo "  T1: $T1_FILE"
    echo "  PET: $PET_FILE"
    
    # Create transform directory
    mkdir -p "data/$SUBJECT/transform"
    
    # 1. Brain extraction
    echo "  1. Brain extraction..."
    bet "$T1_FILE" "data/$SUBJECT/anat/${SUBJECT}_MR_brain.nii.gz" -f 0.3 -B -R
    
    # 2. T1 to MNI
    echo "  2. T1 to MNI..."
    flirt -in "data/$SUBJECT/anat/${SUBJECT}_MR_brain.nii.gz" \
          -ref "$MNI_TEMPLATE" \
          -out "data/$SUBJECT/anat/${SUBJECT}_MR_MNI.nii.gz" \
          -omat "data/$SUBJECT/transform/T1_to_MNI.mat" \
          -dof 12
    
    # 3. PET to T1
    echo "  3. PET to T1..."
    flirt -in "$PET_FILE" \
          -ref "data/$SUBJECT/anat/${SUBJECT}_MR_brain.nii.gz" \
          -out "data/$SUBJECT/pet/${SUBJECT}_PiB_5070_T1.nii.gz" \
          -omat "data/$SUBJECT/transform/PET_to_T1.mat" \
          -dof 6 -cost mutualinfo
    
    # 4. PET to MNI
    echo "  4. PET to MNI..."
    convert_xfm -omat "data/$SUBJECT/transform/PET_to_MNI.mat" \
                -concat "data/$SUBJECT/transform/T1_to_MNI.mat" \
                        "data/$SUBJECT/transform/PET_to_T1.mat"
    
    flirt -in "$PET_FILE" \
          -ref "$MNI_TEMPLATE" \
          -out "data/$SUBJECT/pet/${SUBJECT}_PiB_5070_MNI.nii.gz" \
          -applyxfm -init "data/$SUBJECT/transform/PET_to_MNI.mat"
    
    # 5. Threshold
    echo "  5. Threshold..."
    fslmaths "data/$SUBJECT/pet/${SUBJECT}_PiB_5070_MNI.nii.gz" \
             -thr 0.001 "data/$SUBJECT/pet/${SUBJECT}_PiB_5070_MNI_thr.nii.gz"
    
    echo "  ✓ $SUBJECT processing complete"
done

echo ""
echo "=== ALL SUBJECTS PROCESSED ==="
