#!/bin/bash
echo "=== VISUAL CHECK ==="
echo ""

# Find template
TEMPLATE=$(find $FSLDIR -name "*MNI152*2mm*.nii.gz" 2>/dev/null | head -1)
if [ -z "$TEMPLATE" ]; then
    TEMPLATE="$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz"
fi

echo "Template found: $TEMPLATE"
echo ""
echo "Run this command:"
echo ""
echo "fsleyes $TEMPLATE \\"
echo "       data/AD01/pet/AD01_PiB_5070_MNI_thr.nii.gz -cm hot \\"
echo "       vois/voi_ctx_binary.nii -cm red -a 30 \\"
echo "       vois/voi_cereb_binary.nii -cm green -a 30 &"
echo ""
echo "Check:"
echo "1. Green mask should cover cerebellum (back/bottom of brain)"
echo "2. Red mask should cover cortex (outer surface)"
echo "3. PET signal (hot colors) should align with brain anatomy"
