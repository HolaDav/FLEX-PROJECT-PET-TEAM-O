#!/bin/bash
# Improved VOI alignment

echo "=== IMPROVED VOI ALIGNMENT ==="

MNI_TEMPLATE="/cvmfs/neurodesk.ardc.edu.au/containers/mrtrix3_3.0.1_20200908/mrtrix3_3.0.1_20200908.simg/opt/fsl-6.0.3/data/standard/MNI152_T1_2mm.nii.gz"

# Process each subject
for SUBJECT in AD02 AD04; do  # Focus on problematic ones
    echo ""
    echo "=== Fixing $SUBJECT ==="
    
    PET_FILE="data/$SUBJECT/pet/${SUBJECT}_PiB_5070_MNI_thr.nii.gz"
    
    if [ ! -f "$PET_FILE" ]; then
        echo "PET file not found: $PET_FILE"
        continue
    fi
    
    # 1. Check PET values first
    echo "1. PET value range:"
    fslstats "$PET_FILE" -R -M
    
    # 2. Try BETTER registration with more DOF and search
    echo "2. Improved registration..."
    flirt -in "$MNI_TEMPLATE" \
          -ref "$PET_FILE" \
          -out "vois/MNI_to_${SUBJECT}_improved.nii.gz" \
          -omat "vois/MNI_to_${SUBJECT}_improved.mat" \
          -dof 12 \
          -searchrx -30 30 -searchry -30 30 -searchrz -30 30 \
          -cost mutualinfo
    
    # 3. Apply to VOIs
    echo "3. Applying to VOIs..."
    flirt -in vois/voi_ctx_binary.nii \
          -ref "$PET_FILE" \
          -out "vois/voi_ctx_${SUBJECT}_improved.nii" \
          -applyxfm -init "vois/MNI_to_${SUBJECT}_improved.mat" \
          -interp nearestneighbour
    
    flirt -in vois/voi_cereb_binary.nii \
          -ref "$PET_FILE" \
          -out "vois/voi_cereb_${SUBJECT}_improved.nii" \
          -applyxfm -init "vois/MNI_to_${SUBJECT}_improved.mat" \
          -interp nearestneighbour
    
    # 4. Check cerebellum values
    echo "4. Checking cerebellum values..."
    CEREBELLAR=$(fslstats "$PET_FILE" -k "vois/voi_cereb_${SUBJECT}_improved.nii" -M)
    echo "   Cerebellar mean: $CEREBELLAR (should be ~1-4)"
    
    # 5. Calculate SUVR if reasonable
    if [ $(echo "$CEREBELLAR > 0.5 && $CEREBELLAR < 10" | bc) -eq 1 ]; then
        CORTICAL=$(fslstats "$PET_FILE" -k "vois/voi_ctx_${SUBJECT}_improved.nii" -M)
        SUVR=$(echo "$CORTICAL / $CEREBELLAR" | bc -l)
        echo "   SUVR with improved alignment: $SUVR"
    else
        echo "   Cerebellar value still unreasonable. Manual check needed."
    fi
    
    # 6. Visual check command
    echo "5. Visual check:"
    echo "   fsleyes \"$PET_FILE\" -cm hot \\"
    echo "          \"vois/voi_cereb_${SUBJECT}_improved.nii\" -cm green -a 70 &"
done

echo ""
echo "=== ALIGNMENT FIX ATTEMPTED ==="
