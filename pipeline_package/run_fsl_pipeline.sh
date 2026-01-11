#!/bin/bash
# MINIMAL FSL PIPELINE FOR TEAM TESTING
echo "=== FSL Pipeline Test ==="
echo "Purpose: Reproducibility validation"

# 1. Setup
mkdir -p results
echo "Subject,Group,Cortical,Cerebellar,SUVR,QC" > results/fsl_results.csv

# 2. Test subjects (use their IDs: sub-01 to sub-25)
test_subjects=("sub-01" "sub-02" "sub-03" "sub-20" "sub-21")  # Few for quick test

for subject in "${test_subjects[@]}"; do
    echo "Processing $subject..."
    
    # Convert to your naming (sub-01 → AD01)
    your_id="AD${subject:4:2}"  # sub-01 → AD01
    
    # Find PET file (they need to provide this)
    PET_FILE=""
    for file in "data/$your_id/pet/${your_id}_PiB_5070_MNI.nii.gz" \
                "data/$your_id/pet/${your_id}_PiB_5070_MNI_norm.nii.gz"; do
        if [ -f "../$file" ]; then
            PET_FILE="../$file"
            break
        fi
    done
    
    if [ -z "$PET_FILE" ]; then
        echo "  ⚠️  PET file not found (need: data/$your_id/pet/*_MNI.nii.gz)"
        continue
    fi
    
    # Extract values
    CORTICAL=$(fslstats "$PET_FILE" -k ../vois/voi_ctx_binary.nii.gz -M 2>/dev/null)
    CEREBELLAR=$(fslstats "$PET_FILE" -k ../vois/voi_cereb_binary.nii.gz -M 2>/dev/null)
    
    if [ -n "$CORTICAL" ] && [ -n "$CEREBELLAR" ]; then
        SUVR=$(echo "$CORTICAL / $CEREBELLAR" | bc -l 2>/dev/null)
        QC="PASS"
        if (( $(echo "$CEREBELLAR > 5" | bc -l 2>/dev/null) )); then
            QC="HIGH_CEREB"
        fi
        
        echo "$subject,AD,$CORTICAL,$CEREBELLAR,$SUVR,$QC" >> results/fsl_results.csv
        echo "  SUVR: $SUVR ($QC)"
    else
        echo "  ✗ Extraction failed"
    fi
done

echo ""
echo "=== RESULTS ==="
cat results/fsl_results.csv
echo ""
echo "Compare with their SPM results for same subjects!"
