#!/bin/bash
echo "=== SUVR CALCULATION ==="
echo ""

# AD01
PET_AD="data/AD01/pet/AD01_PiB_5070_MNI_thr.nii.gz"
if [ -f "$PET_AD" ]; then
    echo "Calculating AD01 SUVR..."
    CORTICAL_AD=$(fslstats "$PET_AD" -k vois/voi_ctx_binary.nii -M)
    CEREBELLAR_AD=$(fslstats "$PET_AD" -k vois/voi_cereb_binary.nii -M)
    SUVR_AD=$(echo "$CORTICAL_AD / $CEREBELLAR_AD" | bc -l)
    
    echo "AD01 Results:"
    echo "  Cortical:   $CORTICAL_AD"
    echo "  Cerebellar: $CEREBELLAR_AD"
    echo "  SUVR:       $SUVR_AD"
    echo "  Target:     2.524"
    
    DIFF=$(echo "scale=2; ($SUVR_AD - 2.524) / 2.524 * 100" | bc -l)
    echo "  Difference: ${DIFF}%"
    
    if [ $(echo "sqrt($DIFF*$DIFF) < 5" | bc) -eq 1 ]; then
        echo "  ✓ PASS: Within 5% tolerance"
    else
        echo "  ✗ FAIL: Outside 5% tolerance"
    fi
else
    echo "ERROR: AD01 PET file not found: $PET_AD"
fi

echo ""
# YC101
PET_YC="data/YC101/pet/YC101_PiB_5070_MNI_thr.nii.gz"
if [ -f "$PET_YC" ]; then
    echo "Calculating YC101 SUVR..."
    CORTICAL_YC=$(fslstats "$PET_YC" -k vois/voi_ctx_binary.nii -M)
    CEREBELLAR_YC=$(fslstats "$PET_YC" -k vois/voi_cereb_binary.nii -M)
    SUVR_YC=$(echo "$CORTICAL_YC / $CEREBELLAR_YC" | bc -l)
    
    echo "YC101 Results:"
    echo "  Cortical:   $CORTICAL_YC"
    echo "  Cerebellar: $CEREBELLAR_YC"
    echo "  SUVR:       $SUVR_YC"
    echo "  (Typical YC SUVR: ~1.0-1.2)"
fi

echo ""
echo "=== CALCULATION COMPLETE ==="
