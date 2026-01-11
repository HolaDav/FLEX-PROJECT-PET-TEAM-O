#!/bin/bash
echo "=== COMPLETE PIPELINE WITH REORIENTATION ==="
echo "Follows GAAIN instructions for proper alignment"
echo ""

MNI_TEMPLATE="/cvmfs/neurodesk.ardc.edu.au/containers/mrtrix3_3.0.1_20200908/mrtrix3_3.0.1_20200908.simg/opt/fsl-6.0.3/data/standard/MNI152_T1_2mm.nii.gz"

process_with_reorientation() {
    local subject=$1
    local group=$2
    
    echo "=== PROCESSING $subject WITH REORIENTATION ==="
    
    # Original files
    T1_ORIG="data/$subject/anat/${subject}_MR.nii"
    PET_ORIG="data/$subject/pet/${subject}_PiB_5070.nii"
    
    # Reoriented files
    T1_REORIENTED="data/$subject/anat/${subject}_MR_reoriented.nii"
    PET_REORIENTED="data/$subject/pet/${subject}_PiB_5070_reoriented.nii"
    
    # Step 1: Reorient to standard space
    echo "1. Reorienting to standard space..."
    
    # Backup originals
    cp "$T1_ORIG" "${T1_ORIG%.nii}_backup.nii"
    cp "$PET_ORIG" "${PET_ORIG%.nii}_backup.nii"
    
    # Reorient T1
    echo "   Reorienting T1..."
    fslreorient2std "$T1_ORIG" "$T1_REORIENTED"
    
    if [ $? -eq 0 ] && [ -f "$T1_REORIENTED" ]; then
        mv "$T1_REORIENTED" "$T1_ORIG"
        echo "   ✓ T1 reoriented"
    else
        echo "   ⚠ T1 reorientation may have failed, using original"
    fi
    
    # Reorient PET
    echo "   Reorienting PET..."
    fslreorient2std "$PET_ORIG" "$PET_REORIENTED"
    
    if [ $? -eq 0 ] && [ -f "$PET_REORIENTED" ]; then
        mv "$PET_REORIENTED" "$PET_ORIG"
        echo "   ✓ PET reoriented"
    else
        echo "   ⚠ PET reorientation may have failed, using original"
    fi
    
    # Step 2: Apply intensity scaling if needed (AD02)
    if [ "$subject" = "AD02" ]; then
        echo "2. Applying intensity scaling to AD02..."
        fslmaths "$PET_ORIG" -div 50 "$PET_ORIG"
        echo "   ✓ Intensity scaled ÷50"
    fi
    
    # Step 3: Brain extraction
    echo "3. Brain extraction..."
    bet "$T1_ORIG" "data/$subject/anat/${subject}_MR_brain.nii.gz" \
        -f 0.25 -g -0.1 -B -R
    
    # Step 4: T1 → MNI
    echo "4. T1 to MNI normalization..."
    flirt -in "data/$subject/anat/${subject}_MR_brain.nii.gz" \
        -ref "$MNI_TEMPLATE" \
        -out "data/$subject/anat/${subject}_MR_MNI.nii.gz" \
        -omat "data/$subject/transform/T1_to_MNI.mat" \
        -dof 12 -searchrx -30 30 -searchry -30 30 -searchrz -30 30
    
    # Step 5: PET → T1
    echo "5. PET to T1 coregistration..."
    flirt -in "$PET_ORIG" \
        -ref "data/$subject/anat/${subject}_MR_brain.nii.gz" \
        -out "data/$subject/pet/${subject}_PiB_5070_T1.nii.gz" \
        -omat "data/$subject/transform/PET_to_T1.mat" \
        -dof 6 -cost mutualinfo -searchrx -15 15 -searchry -15 15 -searchrz -15 15
    
    # Step 6: PET → MNI
    echo "6. PET to MNI normalization..."
    convert_xfm -omat "data/$subject/transform/PET_to_MNI.mat" \
        -concat "data/$subject/transform/T1_to_MNI.mat" \
        "data/$subject/transform/PET_to_T1.mat"
    
    flirt -in "$PET_ORIG" \
        -ref "$MNI_TEMPLATE" \
        -out "data/$subject/pet/${subject}_PiB_5070_MNI.nii.gz" \
        -applyxfm -init "data/$subject/transform/PET_to_MNI.mat" \
        -paddingsize 1
    
    # Step 7: Threshold
    echo "7. Intensity threshold..."
    fslmaths "data/$subject/pet/${subject}_PiB_5070_MNI.nii.gz" \
        -thr 0.001 "data/$subject/pet/${subject}_PiB_5070_MNI_thr.nii.gz"
    
    echo "✓ $subject processed with reorientation"
    echo ""
}

# Test on problem subjects first
echo "=== TESTING ON PROBLEM SUBJECTS ==="
process_with_reorientation "AD04" "AD"
process_with_reorientation "AD02" "AD"

echo ""
echo "=== VISUAL CHECK COMMANDS ==="
echo "Check AD04 alignment:"
echo "  fsleyes '$MNI_TEMPLATE' data/AD04/pet/AD04_PiB_5070_MNI_thr.nii.gz -cm hot &"
echo ""
echo "Check AD02 alignment:"
echo "  fsleyes '$MNI_TEMPLATE' data/AD02/pet/AD02_PiB_5070_MNI_thr.nii.gz -cm hot &"
