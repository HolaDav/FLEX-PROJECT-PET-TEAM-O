#!/bin/bash
echo "=== NORMALIZING PET FILES ==="
echo "Scaling all PET files to similar intensity ranges"

# First, find typical cerebellar value from good subjects
echo "Finding reference cerebellar value from good subjects..."
REF_CEREBELLAR=3.5  # Approximate from AD01

for subject in AD01 AD02 AD03 AD04 AD05 AD06 AD07 AD08 AD09 AD10 AD11 AD12 AD13 AD14 AD15 AD16 AD17 AD18 AD19 AD20 AD21 AD22 AD23 AD24 AD25; do
    if [ ! -d "data/$subject" ]; then
        continue
    fi
    
    echo ""
    echo "--- $subject ---"
    
    # Find main PET file
    PET_FILE="data/$subject/pet/${subject}_PiB_5070_MNI.nii.gz"
    if [ ! -f "$PET_FILE" ]; then
        echo "  No main PET file, skipping"
        continue
    fi
    
    # Check current cerebellar value
    CURRENT_CEREB=$(fslstats "$PET_FILE" -k vois/voi_cereb_binary.nii.gz -M 2>/dev/null)
    echo "  Current cerebellar mean: $CURRENT_CEREB"
    
    if [ -n "$CURRENT_CEREB" ] && (( $(echo "$CURRENT_CEREB > 10" | bc -l 2>/dev/null) )); then
        echo "  ⚠️  Cerebellar value too high (>10), needs normalization"
        
        # Calculate scaling factor
        SCALE_FACTOR=$(echo "$REF_CEREBELLAR / $CURRENT_CEREB" | bc -l 2>/dev/null)
        echo "  Scaling factor: $SCALE_FACTOR"
        
        # Apply scaling
        fslmaths "$PET_FILE" -mul $SCALE_FACTOR "data/$subject/pet/${subject}_PiB_5070_MNI_norm.nii.gz"
        echo "  Created normalized file"
        
    elif [ -n "$CURRENT_CEREB" ] && (( $(echo "$CURRENT_CEREB > 0.5" | bc -l 2>/dev/null) )); then
        echo "  ✓ Cerebellar value looks OK"
    fi
done
