#!/bin/bash
SUBJ_ID=$1
if [ -z "$SUBJ_ID" ]; then
    echo "Usage: $0 <subject> (e.g., AD01)"
    exit 1
fi

echo "=== Quality Check for $SUBJ_ID ==="
echo ""

echo "1. Image dimensions:"
PET_DIM=$(fslinfo $SUBJ_ID/pet/${SUBJ_ID}_PiB_5070_MNI_thr.nii.gz | grep -E "dim1|dim2|dim3" | awk '{print $2}' | tr '\n' ' ')
MNI_DIM=$(fslinfo $FSLDIR/data/standard/MNI152_T1_2mm.nii.gz | grep -E "dim1|dim2|dim3" | awk '{print $2}' | tr '\n' ' ')
echo "   PET:  $PET_DIM"
echo "   MNI:  $MNI_DIM"

echo ""
echo "2. Value ranges:"
fslstats $SUBJ_ID/pet/${SUBJ_ID}_PiB_5070_MNI_thr.nii.gz -R -M -S

echo ""
echo "3. Cerebellar region:"
CEREB_VAL=$(fslstats $SUBJ_ID/pet/${SUBJ_ID}_PiB_5070_MNI_thr.nii.gz -k vois/voi_cereb_binary.nii -M)
echo "   Mean: $CEREB_VAL (should be ~1-2)"

echo ""
echo "4. Visual check command:"
echo "   fsleyes $FSLDIR/data/standard/MNI152_T1_2mm.nii.gz \\"
echo "          $SUBJ_ID/pet/${SUBJ_ID}_PiB_5070_MNI_thr.nii.gz -cm hot \\"
echo "          vois/voi_ctx_binary.nii -cm red -a 30 \\"
echo "          vois/voi_cereb_binary.nii -cm green -a 30 &"

echo ""
echo "=== Quality check complete ==="
