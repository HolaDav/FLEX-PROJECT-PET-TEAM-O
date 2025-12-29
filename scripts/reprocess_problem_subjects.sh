#!/bin/bash
echo "=== RE-PROCESSING PROBLEM SUBJECTS ==="
echo "Fixing AD02 and AD04"
echo ""

MNI_TEMPLATE="/cvmfs/neurodesk.ardc.edu.au/containers/mrtrix3_3.0.1_20200908/mrtrix3_3.0.1_20200908.simg/opt/fsl-6.0.3/data/standard/MNI152_T1_2mm.nii.gz"

reprocess_subject() {
    local subject=$1
    local group=$2
    
    echo "=== RE-PROCESSING $subject ==="
    
    T1_FILE="data/$subject/anat/${subject}_MR.nii"
    PET_FILE="data/$subject/pet/${subject}_PiB_5070.nii"
    
    # Backup old results
    mv "data/$subject/pet/${subject}_PiB_5070_MNI_thr.nii.gz" \
       "data/$subject/pet/${subject}_PiB_5070_MNI_thr_BACKUP.nii.gz" 2>/dev/null
    
    # 1. Check if PET needs intensity scaling (AD02 issue)
    echo "Checking PET intensity..."
    PET_STATS=$(fslstats "$PET_FILE" -R -M 2>/dev/null)
    echo "PET stats: $PET_STATS"
    
    # For AD02, apply scaling if values are huge
    if [ "$subject" = "AD02" ]; then
        echo "Applying intensity scaling to AD02..."
        fslmaths "$PET_FILE" -div 50 "data/$subject/pet/${subject}_PiB_5070_scaled.nii"
        PET_FILE="data/$subject/pet/${subject}_PiB_5070_scaled.nii"
    fi
    
    # 2. Brain extraction with better parameters
    echo "Brain extraction..."
    bet "$T1_FILE" "data/$subject/anat/${subject}_MR_brain.nii.gz" \
        -f 0.25 -g -0.1 -B -R  # Tighter parameters
    
    # 3. T1 → MNI with better alignment
    echo "T1 to MNI (improved)..."
    flirt -in "data/$subject/anat/${subject}_MR_brain.nii.gz" \
        -ref "$MNI_TEMPLATE" \
        -out "data/$subject/anat/${subject}_MR_MNI_improved.nii.gz" \
        -omat "data/$subject/transform/T1_to_MNI_improved.mat" \
        -dof 12 -searchrx -30 30 -searchry -30 30 -searchrz -30 30
    
    # 4. PET → T1 with better coregistration
    echo "PET to T1 coregistration..."
    flirt -in "$PET_FILE" \
        -ref "data/$subject/anat/${subject}_MR_brain.nii.gz" \
        -out "data/$subject/pet/${subject}_PiB_5070_T1_improved.nii.gz" \
        -omat "data/$subject/transform/PET_to_T1_improved.mat" \
        -dof 6 -cost mutualinfo -searchrx -15 15 -searchry -15 15 -searchrz -15 15
    
    # 5. PET → MNI
    echo "PET to MNI..."
    convert_xfm -omat "data/$subject/transform/PET_to_MNI_improved.mat" \
        -concat "data/$subject/transform/T1_to_MNI_improved.mat" \
        "data/$subject/transform/PET_to_T1_improved.mat"
    
    flirt -in "$PET_FILE" \
        -ref "$MNI_TEMPLATE" \
        -out "data/$subject/pet/${subject}_PiB_5070_MNI_improved.nii.gz" \
        -applyxfm -init "data/$subject/transform/PET_to_MNI_improved.mat" \
        -paddingsize 1
    
    # 6. Threshold
    echo "Thresholding..."
    fslmaths "data/$subject/pet/${subject}_PiB_5070_MNI_improved.nii.gz" \
        -thr 0.001 "data/$subject/pet/${subject}_PiB_5070_MNI_thr_improved.nii.gz"
    
    echo "✓ $subject re-processed"
    echo ""
}

# Re-process problem subjects
reprocess_subject "AD02" "AD"
reprocess_subject "AD04" "AD"
