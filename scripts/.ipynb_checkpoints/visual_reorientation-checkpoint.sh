#!/bin/bash
echo "=== VISUAL REORIENTATION FOR BETTER ALIGNMENT ==="
echo "Based on GAAIN instructions"
echo ""

MNI_TEMPLATE="/cvmfs/neurodesk.ardc.edu.au/containers/mrtrix3_3.0.1_20200908/mrtrix3_3.0.1_20200908.simg/opt/fsl-6.0.3/data/standard/MNI152_T1_2mm.nii.gz"

reorient_subject() {
    local subject=$1
    local group=$2
    
    echo "=== REORIENTING $subject ==="
    
    T1_FILE="data/$subject/anat/${subject}_MR.nii"
    PET_FILE="data/$subject/pet/${subject}_PiB_5070.nii"
    
    # Backup original files
    cp "$T1_FILE" "${T1_FILE%.nii}_original.nii"
    cp "$PET_FILE" "${PET_FILE%.nii}_original.nii"
    
    echo "1. Visual inspection command:"
    echo "   fsleyes '$MNI_TEMPLATE' '$T1_FILE' &"
    echo ""
    echo "2. Check if reorientation is needed:"
    echo "   - Is anterior commissure near [0 0 0]?"
    echo "   - Is orientation close to MNI?"
    echo "   - Does brain look 'wrapped' or tilted?"
    echo ""
    echo "3. If reorientation needed, use fslreorient2std:"
    echo "   fslreorient2std '$T1_FILE' '${T1_FILE%.nii}_reoriented.nii'"
    echo "   fslreorient2std '$PET_FILE' '${PET_FILE%.nii}_reoriented.nii'"
    echo ""
    echo "4. For manual reorientation (if fslreorient2std doesn't work):"
    echo "   fslswapdim '$T1_FILE' -x y z '${T1_FILE%.nii}_reoriented.nii'"
    echo "   (adjust -x/y/z based on what you see)"
    echo ""
    echo "After reorientation, update file paths in processing scripts."
    echo ""
}

# Check which subjects need reorientation
echo "=== SUBJECTS TO CHECK ==="
echo "Based on previous issues:"
echo "1. AD04 - High cerebellar values (9.8) suggests misalignment"
echo "2. AD02 - Extreme values may indicate orientation issue"
echo "3. All subjects - Udunna noted 'brains look really wrapped'"
echo ""

# Create a test reorientation for one subject first
echo "=== TEST REORIENTATION FOR AD04 ==="
AD04_T1="data/AD04/anat/AD04_MR.nii"
AD04_T1_REORIENTED="data/AD04/anat/AD04_MR_reoriented.nii"

if [ -f "$AD04_T1" ]; then
    echo "1. First, check current orientation:"
    fslhd "$AD04_T1" | grep -E "qform|sform|sto_xyz"
    echo ""
    
    echo "2. Try automatic reorientation to standard:"
    fslreorient2std "$AD04_T1" "$AD04_T1_REORIENTED"
    
    if [ $? -eq 0 ] && [ -f "$AD04_T1_REORIENTED" ]; then
        echo "✓ Reorientation successful"
        echo "Original file backed up as: ${AD04_T1%.nii}_original.nii"
        
        # Replace with reoriented file
        mv "$AD04_T1_REORIENTED" "$AD04_T1"
        
        echo "3. Now re-process AD04 with reoriented T1:"
        echo "   Run the reprocessing script again"
    else
        echo "✗ Automatic reorientation failed"
        echo "Try manual inspection with: fsleyes '$MNI_TEMPLATE' '$AD04_T1' &"
    fi
else
    echo "✗ AD04 T1 file not found"
fi
