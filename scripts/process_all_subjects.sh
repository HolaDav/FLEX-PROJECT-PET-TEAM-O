#!/bin/bash
echo "=== PROCESSING ALL SUBJECTS WITH FIXED ORIENTATION ==="
echo "AD01-AD25 and YC101-YC125"
echo ""

MNI_TEMPLATE="/cvmfs/neurodesk.ardc.edu.au/containers/mrtrix3_3.0.1_20200908/mrtrix3_3.0.1_20200908.simg/opt/fsl-6.0.3/data/standard/MNI152_T1_2mm.nii.gz"

# Check which subjects actually have data
echo "=== CHECKING AVAILABLE DATA ==="
AVAILABLE_SUBJECTS=()

for i in {1..25}; do
    AD_SUBJ=$(printf "AD%02d" $i)
    # YC_SUBJ=$(printf "YC1%02d" $i)
    
    if [ -f "data/$AD_SUBJ/anat/${AD_SUBJ}_MR.nii" ] && [ -f "data/$AD_SUBJ/pet/${AD_SUBJ}_PiB_5070.nii" ]; then
        echo "✓ $AD_SUBJ: Data available"
        AVAILABLE_SUBJECTS+=("$AD_SUBJ")
    else
        echo "✗ $AD_SUBJ: Missing data"
    fi
    
    if [ -f "data/$YC_SUBJ/anat/${YC_SUBJ}_MR.nii" ] && [ -f "data/$YC_SUBJ/pet/${YC_SUBJ}_PiB_5070.nii" ]; then
        echo "✓ $YC_SUBJ: Data available"
        AVAILABLE_SUBJECTS+=("$YC_SUBJ")
    else
        echo "✗ $YC_SUBJ: Missing data"
    fi
done

echo ""
echo "Found ${#AVAILABLE_SUBJECTS[@]} subjects with data"
echo ""

# Process each available subject
for SUBJECT in "${AVAILABLE_SUBJECTS[@]}"; do
    echo "=== PROCESSING $SUBJECT ==="
    
    if [[ $SUBJECT == AD* ]]; then
        GROUP="AD"
    else
        GROUP="YC"
    fi
    
    T1_FILE="data/$SUBJECT/anat/${SUBJECT}_MR.nii"
    PET_FILE="data/$SUBJECT/pet/${SUBJECT}_PiB_5070.nii"
    
    # Create directories
    mkdir -p "data/$SUBJECT/transform"
    
    # Step 1: Reorient if needed
    echo "1. Checking/reorienting..."
    fslreorient2std "$T1_FILE" "${T1_FILE%.nii}_reoriented.nii" 2>/dev/null
    if [ -f "${T1_FILE%.nii}_reoriented.nii" ]; then
        mv "${T1_FILE%.nii}_reoriented.nii" "$T1_FILE"
        echo "   T1 reoriented"
    fi
    
    fslreorient2std "$PET_FILE" "${PET_FILE%.nii}_reoriented.nii" 2>/dev/null
    if [ -f "${PET_FILE%.nii}_reoriented.nii" ]; then
        mv "${PET_FILE%.nii}_reoriented.nii" "$PET_FILE"
        echo "   PET reoriented"
    fi
    
    # Step 2: Brain extraction
    echo "2. Brain extraction..."
    bet "$T1_FILE" "data/$SUBJECT/anat/${SUBJECT}_MR_brain.nii.gz" \
        -f 0.25 -g -0.1 -B -R
    
    # Step 3: T1 → MNI
    echo "3. T1 to MNI..."
    flirt -in "data/$SUBJECT/anat/${SUBJECT}_MR_brain.nii.gz" \
        -ref "$MNI_TEMPLATE" \
        -out "data/$SUBJECT/anat/${SUBJECT}_MR_MNI.nii.gz" \
        -omat "data/$SUBJECT/transform/T1_to_MNI.mat" \
        -dof 12 -searchrx -30 30 -searchry -30 30 -searchrz -30 30
    
    # Step 4: PET → T1
    echo "4. PET to T1..."
    flirt -in "$PET_FILE" \
        -ref "data/$SUBJECT/anat/${SUBJECT}_MR_brain.nii.gz" \
        -out "data/$SUBJECT/pet/${SUBJECT}_PiB_5070_T1.nii.gz" \
        -omat "data/$SUBJECT/transform/PET_to_T1.mat" \
        -dof 6 -cost mutualinfo -searchrx -15 15 -searchry -15 15 -searchrz -15 15
    
    # Step 5: PET → MNI
    echo "5. PET to MNI..."
    convert_xfm -omat "data/$SUBJECT/transform/PET_to_MNI.mat" \
        -concat "data/$SUBJECT/transform/T1_to_MNI.mat" \
        "data/$SUBJECT/transform/PET_to_T1.mat"
    
    flirt -in "$PET_FILE" \
        -ref "$MNI_TEMPLATE" \
        -out "data/$SUBJECT/pet/${SUBJECT}_PiB_5070_MNI.nii.gz" \
        -applyxfm -init "data/$SUBJECT/transform/PET_to_MNI.mat" \
        -paddingsize 1
    
    # Step 6: Threshold
    echo "6. Threshold..."
    fslmaths "data/$SUBJECT/pet/${SUBJECT}_PiB_5070_MNI.nii.gz" \
        -thr 0.001 "data/$SUBJECT/pet/${SUBJECT}_PiB_5070_MNI_thr.nii.gz"
    
    echo "✓ $SUBJECT processed"
    echo ""
done

echo "=== PROCESSING COMPLETE ==="
echo "Processed ${#AVAILABLE_SUBJECTS[@]} new subjects"
