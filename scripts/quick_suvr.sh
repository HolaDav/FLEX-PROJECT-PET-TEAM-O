#!/bin/bash
echo "=== QUICK SUVR CALCULATION ==="

PET_FILE="data/AD01/pet/AD01_PiB_5070_MNI_thr.nii.gz"

if [ ! -f "$PET_FILE" ]; then
    echo "ERROR: PET file not found: $PET_FILE"
    echo "Available files in data/AD01/pet/:"
    ls -la data/AD01/pet/
    exit 1
fi

echo "Calculating SUVR for AD01..."
CORTICAL=$(fslstats "$PET_FILE" -k vois/voi_ctx_binary.nii -M)
CEREBELLAR=$(fslstats "$PET_FILE" -k vois/voi_cereb_binary.nii -M)
SUVR=$(echo "$CORTICAL / $CEREBELLAR" | bc -l)

echo ""
echo "RESULTS:"
echo "Cortical mean:   $CORTICAL"
echo "Cerebellar mean: $CEREBELLAR"
echo "SUVR:            $SUVR"
echo "Target:          2.524"

DIFF=$(echo "scale=2; ($SUVR - 2.524) / 2.524 * 100" | bc -l)
echo "Difference:      ${DIFF}%"

if [ $(echo "sqrt($DIFF*$DIFF) < 5" | bc) -eq 1 ]; then
    echo "✓ WITHIN 5% TOLERANCE"
else
    echo "✗ OUTSIDE 5% TOLERANCE"
fi
