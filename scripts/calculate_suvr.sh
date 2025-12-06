#!/bin/bash
# Calculate SUVR for one subject

SUBJ_ID=$1  # e.g., AD01 or YC101
if [ -z "$SUBJ_ID" ]; then
    echo "Usage: $0 <subject> (e.g., AD01)"
    exit 1
fi

PET_FILE="$SUBJ_ID/pet/${SUBJ_ID}_PiB_5070_MNI_thr.nii.gz"

echo "=== Calculating SUVR for $SUBJ_ID ==="

if [ ! -f "$PET_FILE" ]; then
    echo "ERROR: PET file not found: $PET_FILE"
    exit 1
fi

if [ ! -f "vois/voi_ctx_binary.nii" ]; then
    echo "ERROR: Run process_vois.sh first"
    exit 1
fi

echo "Extracting regional values..."
CORTICAL=$(fslstats "$PET_FILE" -k vois/voi_ctx_binary.nii -M)
CEREBELLAR=$(fslstats "$PET_FILE" -k vois/voi_cereb_binary.nii -M)

SUVR=$(echo "$CORTICAL / $CEREBELLAR" | bc -l)

echo ""
echo "RESULTS for $SUBJ_ID:"
echo "----------------------"
echo "Cortical mean:    $CORTICAL"
echo "Cerebellar mean:  $CEREBELLAR"
echo "SUVR:             $SUVR"

if [ "$SUBJ_ID" = "AD01" ]; then
    echo "Published SUVR:   2.524"
    DIFF=$(echo "scale=2; ($SUVR - 2.524) / 2.524 * 100" | bc -l)
    echo "Difference:       ${DIFF}%"
    
    if [ $(echo "sqrt(($DIFF * $DIFF)) < 5" | bc) -eq 1 ]; then
        echo "✓ Within 5% tolerance"
    else
        echo "✗ Exceeds 5% tolerance"
    fi
fi

echo "=== Calculation complete ==="
