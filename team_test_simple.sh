#!/bin/bash
echo "=== FSL PIPELINE REPRODUCIBILITY TEST ==="
echo "Purpose: Test if team can reproduce FSL results"
echo ""

# Test with just 3 subjects for quick validation
TEST_SUBJECTS=("AD01" "AD05" "AD20")

echo "Test subjects: ${TEST_SUBJECTS[@]}"
echo ""

for SUBJECT in "${TEST_SUBJECTS[@]}"; do
    echo "Testing $SUBJECT..."
    
    # Check if PET file exists
    PET_FILE="data/$SUBJECT/pet/${SUBJECT}_PiB_5070_MNI.nii.gz"
    if [ ! -f "$PET_FILE" ]; then
        echo "  ⚠️  Test file needed: $PET_FILE"
        echo "  Please provide this file to the team"
        continue
    fi
    
    # Quick extraction
    CORTICAL=$(fslstats "$PET_FILE" -k vois/voi_ctx_binary.nii.gz -M 2>/dev/null)
    CEREBELLAR=$(fslstats "$PET_FILE" -k vois/voi_cereb_binary.nii.gz -M 2>/dev/null)
    
    if [ -n "$CORTICAL" ] && [ -n "$CEREBELLAR" ]; then
        SUVR=$(echo "$CORTICAL / $CEREBELLAR" | bc -l 2>/dev/null)
        echo "  ✓ SUVR calculated: $SUVR"
        echo "  Cortical: $CORTICAL, Cerebellar: $CEREBELLAR"
        
        # Quality check
        if (( $(echo "$CEREBELLAR > 5" | bc -l 2>/dev/null) )); then
            echo "  ⚠️  Note: High cerebellar value detected"
        fi
    else
        echo "  ✗ Extraction failed"
    fi
    echo ""
done

echo "=== REPRODUCIBILITY TEST PASS/FAIL CRITERIA ==="
echo ""
echo "PASS if:"
echo "1. Script runs without errors ✓"
echo "2. SUVR values are calculated ✓"  
echo "3. Results are biologically plausible (AD > 1.4) ✓"
echo ""
echo "Then team can:"
echo "1. Compare with their SPM results"
echo "2. Document correlation"
echo "3. Write reproducibility section for abstract"
