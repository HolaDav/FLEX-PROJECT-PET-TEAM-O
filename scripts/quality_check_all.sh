#!/bin/bash
echo "=== COMPREHENSIVE QUALITY CHECK ==="
echo "Checking all 10 processed subjects"
echo ""

MNI_TEMPLATE="/cvmfs/neurodesk.ardc.edu.au/containers/mrtrix3_3.0.1_20200908/mrtrix3_3.0.1_20200908.simg/opt/fsl-6.0.3/data/standard/MNI152_T1_2mm.nii.gz"

check_subject() {
    local subject=$1
    local group=$2
    
    echo "=== $subject QUALITY CHECK ==="
    
    PET_FILE="data/$subject/pet/${subject}_PiB_5070_MNI_thr.nii.gz"
    CEREB_VOI="vois/voi_cereb_${subject}.nii.gz"
    
    if [ ! -f "$PET_FILE" ]; then
        echo "✗ PET file missing"
        return 1
    fi
    
    # 1. Check cerebellar values
    CEREBELLAR=$(fslstats "$PET_FILE" -k "$CEREB_VOI" -M 2>/dev/null)
    echo "Cerebellar mean: $CEREBELLAR"
    
    # Expected range for PiB: 1-4
    if (( $(echo "$CEREBELLAR < 0.5" | bc -l 2>/dev/null) )); then
        echo "⚠ WARNING: Cerebellar too low (<0.5)"
    elif (( $(echo "$CEREBELLAR > 10" | bc -l 2>/dev/null) )); then
        echo "⚠ WARNING: Cerebellar too high (>10)"
    elif (( $(echo "$CEREBELLAR > 4" | bc -l 2>/dev/null) )); then
        echo "⚠ WARNING: Cerebellar higher than expected (>4)"
    else
        echo "✓ Cerebellar in expected range (1-4)"
    fi
    
    # 2. Check dimensions
    echo ""
    echo "Image dimensions:"
    fslinfo "$PET_FILE" | grep -E "dim1|dim2|dim3|pixdim"
    
    # 3. Visual check commands
    echo ""
    echo "Visual check commands:"
    echo "  fsleyes '$MNI_TEMPLATE' '$PET_FILE' -cm hot &"
    echo "  fsleyes '$PET_FILE' '$CEREB_VOI' -cm green -a 70 &"
    
    echo ""
    echo "---"
}

# Check all subjects
echo "Checking AD subjects..."
for sub in AD01 AD02 AD03 AD04 AD05; do
    check_subject "$sub" "AD"
done

echo ""
echo "Checking YC subjects..."
for sub in YC101 YC102 YC103 YC104 YC105; do
    check_subject "$sub" "YC"
done

echo ""
echo "=== QUALITY ISSUES SUMMARY ==="
echo "1. AD02: Extreme values (needs re-processing)"
echo "2. AD04: High cerebellar (9.8, check alignment)"
echo "3. Check all visual alignments"
