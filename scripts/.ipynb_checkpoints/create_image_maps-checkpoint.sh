#!/bin/bash
echo "=== CREATING IMAGE MAPS FOR SUPERVISOR REVIEW ==="
echo ""

# Check if we have necessary files for AD01 (our validated subject)
SUBJECT="AD01"
PET_FILE="data/${SUBJECT}/pet/${SUBJECT}_PiB_5070_MNI_thr.nii.gz"
CEREB_MASK="vois/voi_cereb_${SUBJECT}.nii"
CTX_MASK="vois/voi_ctx_${SUBJECT}.nii"
MNI_TEMPLATE="/cvmfs/neurodesk.ardc.edu.au/containers/mrtrix3_3.0.1_20200908/mrtrix3_3.0.1_20200908.simg/opt/fsl-6.0.3/data/standard/MNI152_T1_2mm.nii.gz"

echo "Checking files for ${SUBJECT}..."
if [ ! -f "$PET_FILE" ]; then
    echo "ERROR: PET file not found: $PET_FILE"
    exit 1
fi

if [ ! -f "$CEREB_MASK" ]; then
    echo "ERROR: Cerebellum mask not found: $CEREB_MASK"
    echo "Creating aligned masks first..."
    
    # Align VOIs if not already done
    flirt -in "$MNI_TEMPLATE" \
          -ref "$PET_FILE" \
          -out "vois/MNI_to_${SUBJECT}.nii.gz" \
          -omat "vois/MNI_to_${SUBJECT}.mat" \
          -dof 6
    
    flirt -in vois/voi_ctx_binary.nii \
          -ref "$PET_FILE" \
          -out "vois/voi_ctx_${SUBJECT}.nii" \
          -applyxfm -init "vois/MNI_to_${SUBJECT}.mat" \
          -interp nearestneighbour
    
    flirt -in vois/voi_cereb_binary.nii \
          -ref "$PET_FILE" \
          -out "vois/voi_cereb_${SUBJECT}.nii" \
          -applyxfm -init "vois/MNI_to_${SUBJECT}.mat" \
          -interp nearestneighbour
fi

echo "Files verified. Creating visualizations..."
echo ""

# Create slice images at different planes
# We'll create axial (horizontal), coronal (front-back), and sagittal (side) views

# 1. Create cerebellum overlay (green) - Axial slice at z=30 (cerebellum level)
echo "1. Creating cerebellum overlay (axial slice)..."
fslroi "$PET_FILE" temp_pet_slice.nii.gz 0 -1 0 -1 30 1
fslroi "$CEREB_MASK" temp_cereb_slice.nii.gz 0 -1 0 -1 30 1
fslmaths temp_cereb_slice.nii.gz -mul 2 temp_cereb_overlay.nii.gz
fslmaths temp_pet_slice.nii.gz -add temp_cereb_overlay.nii.gz temp_combined_cereb.nii.gz

# 2. Create cortical overlay (red) - Axial slice at z=50 (cortex level)
echo "2. Creating cortical overlay (axial slice)..."
fslroi "$PET_FILE" temp_pet_slice2.nii.gz 0 -1 0 -1 50 1
fslroi "$CTX_MASK" temp_ctx_slice.nii.gz 0 -1 0 -1 50 1
fslmaths temp_ctx_slice.nii.gz -mul 3 temp_ctx_overlay.nii.gz
fslmaths temp_pet_slice2.nii.gz -add temp_ctx_overlay.nii.gz temp_combined_ctx.nii.gz

# 3. Create combined overlay - All masks
echo "3. Creating combined overlay..."
fslmaths "$CEREB_MASK" -mul 2 temp_cereb_full.nii.gz
fslmaths "$CTX_MASK" -mul 3 temp_ctx_full.nii.gz
fslmaths "$PET_FILE" -add temp_cereb_full.nii.gz -add temp_ctx_full.nii.gz temp_combined_full.nii.gz

# 4. Create orthogonal views (3-slice view)
echo "4. Creating orthogonal views..."
# We'll use fsleyes render command if available, or create manually

# Clean up temp files
rm -f temp_*.nii.gz

echo ""
echo "=== CREATING VISUALIZATION COMMANDS ==="
echo ""
echo "To view the images, run these commands in Neurodesk:"
echo ""
echo "1. CEREBELLUM ALIGNMENT CHECK (green mask should be in cerebellum):"
echo "   fsleyes \"$PET_FILE\" -cm hot \\"
echo "          \"$CEREB_MASK\" -cm green -a 70 &"
echo ""
echo "2. CORTICAL ALIGNMENT CHECK (red mask should cover cortex):"
echo "   fsleyes \"$PET_FILE\" -cm hot \\"
echo "          \"$CTX_MASK\" -cm red -a 50 &"
echo ""
echo "3. ALL MASKS OVERLAY:"
echo "   fsleyes \"$PET_FILE\" -cm hot \\"
echo "          \"$CEREB_MASK\" -cm green -a 70 \\"
echo "          \"$CTX_MASK\" -cm red -a 50 &"
echo ""
echo "4. NORMALIZATION CHECK (PET should align with MNI template):"
echo "   fsleyes \"$MNI_TEMPLATE\" \\"
echo "          \"$PET_FILE\" -cm hot -a 70 &"
