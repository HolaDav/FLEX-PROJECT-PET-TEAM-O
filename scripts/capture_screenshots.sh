#!/bin/bash
SUBJECT="AD01"
PET="data/${SUBJECT}/pet/${SUBJECT}_PiB_5070_MNI_thr.nii.gz"
CEREB="vois/voi_cereb_${SUBJECT}.nii"
CTX="vois/voi_ctx_${SUBJECT}.nii"

echo "Attempting to create screenshots..."
echo "Note: This may require a display. If it fails, manual screenshots are needed."

# Try to create images (may fail without display)
fslmaths "$PET" -Tmean visual_maps/pet_mean.nii.gz

# Create simple montage using slicer instead
echo "Creating image slices using fslslice..."
slicer visual_maps/pet_mean.nii.gz -a visual_maps/pet_slices.png 2>/dev/null || echo "slicer not available"

echo "If automated screenshots fail, please:"
echo "1. Run the visualization commands manually"
echo "2. Take screenshots"
echo "3. Save to visual_maps/ folder"
