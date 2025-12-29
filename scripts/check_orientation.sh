#!/bin/bash
echo "=== CHECKING IMAGE ORIENTATION ==="
echo "Critical step for proper alignment"
echo ""

MNI_TEMPLATE="/cvmfs/neurodesk.ardc.edu.au/containers/mrtrix3_3.0.1_20200908/mrtrix3_3.0.1_20200908.simg/opt/fsl-6.0.3/data/standard/MNI152_T1_2mm.nii.gz"

check_orientation() {
    local subject=$1
    local group=$2
    
    echo "=== $subject ORIENTATION CHECK ==="
    
    T1_FILE="data/$subject/anat/${subject}_MR.nii"
    PET_FILE="data/$subject/pet/${subject}_PiB_5070.nii"
    
    if [ ! -f "$T1_FILE" ]; then
        echo "✗ T1 file missing"
        return 1
    fi
    
    echo "1. Orientation matrix (qform):"
    fslhd "$T1_FILE" | grep -A1 "qform" || echo "No qform info"
    
    echo ""
    echo "2. Recommended: Visual check with MNI template"
    echo "   Command: fsleyes '$MNI_TEMPLATE' '$T1_FILE' &"
    echo ""
    echo "3. Check if reorientation needed:"
    echo "   Run: fslreorient2std -v '$T1_FILE'"
    echo ""
    
    # Check if image is close to standard orientation
    echo "4. Quick check with fslreorient2std:"
    fslreorient2std "$T1_FILE" /tmp/test_reorient.nii 2>&1 | head -20
    
    echo "---"
}

# Check problem subjects first
echo "=== CHECKING PROBLEM SUBJECTS ==="
check_orientation "AD04" "AD"
check_orientation "AD02" "AD"

echo ""
echo "=== CHECKING GOOD SUBJECTS FOR COMPARISON ==="
check_orientation "AD01" "AD"
check_orientation "YC101" "YC"
