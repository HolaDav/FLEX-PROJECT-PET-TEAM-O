#!/bin/bash
echo "=== Processing GAAIN VOIs ==="

if [ ! -f "vois/voi_ctx_2mm.nii" ] || [ ! -f "vois/voi_CerebGry_2mm.nii" ]; then
    echo "ERROR: VOI files not found"
    exit 1
fi

echo "1. Converting probability maps to binary masks..."
fslmaths vois/voi_ctx_2mm.nii -thr 0.5 -bin vois/voi_ctx_binary.nii
fslmaths vois/voi_CerebGry_2mm.nii -thr 0.5 -bin vois/voi_cereb_binary.nii

echo "2. Verifying mask sizes:"
echo "   Cortical mask: $(fslstats vois/voi_ctx_binary.nii -V | awk '{print $1}') voxels"
echo "   Cerebellar mask: $(fslstats vois/voi_cereb_binary.nii -V | awk '{print $1}') voxels"

echo "=== VOIs processed ==="
