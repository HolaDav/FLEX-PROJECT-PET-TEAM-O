#!/bin/bash
echo "=== CREATING BINARY MASKS ==="

# Check what we have
echo "Available masks:"
for mask in vois/voi_*.nii vois/voi_*.nii.gz; do
    if [ -f "$mask" ]; then
        echo "  $mask"
    fi
done

# Create binary versions
echo -e "\nCreating binary masks..."

# Cortical mask
if [ -f "vois/voi_ctx_2mm.nii" ]; then
    echo "Creating cortical binary mask..."
    fslmaths vois/voi_ctx_2mm.nii -bin vois/voi_ctx_binary.nii.gz
elif [ -f "vois/voi_ctx_2mm.nii.gz" ]; then
    echo "Creating cortical binary mask..."
    fslmaths vois/voi_ctx_2mm.nii.gz -bin vois/voi_ctx_binary.nii.gz
fi

# Cerebellar Gray mask (CG from GAIN table)
if [ -f "vois/voi_CerebGry_2mm.nii" ]; then
    echo "Creating cerebellar gray binary mask..."
    fslmaths vois/voi_CerebGry_2mm.nii -bin vois/voi_cereb_binary.nii.gz
elif [ -f "vois/voi_CerebGry_2mm.nii.gz" ]; then
    echo "Creating cerebellar gray binary mask..."
    fslmaths vois/voi_CerebGry_2mm.nii.gz -bin vois/voi_cereb_binary.nii.gz
fi

# Whole Cerebellum mask (WC from GAIN table)
if [ -f "vois/voi_WhlCbl_2mm.nii" ]; then
    echo "Creating whole cerebellum binary mask..."
    fslmaths vois/voi_WhlCbl_2mm.nii -bin vois/voi_wc_binary.nii.gz
elif [ -f "vois/voi_WhlCbl_2mm.nii.gz" ]; then
    echo "Creating whole cerebellum binary mask..."
    fslmaths vois/voi_WhlCbl_2mm.nii.gz -bin vois/voi_wc_binary.nii.gz
fi

# Pons mask
if [ -f "vois/voi_Pons_2mm.nii" ]; then
    echo "Creating pons binary mask..."
    fslmaths vois/voi_Pons_2mm.nii -bin vois/voi_pons_binary.nii.gz
elif [ -f "vois/voi_Pons_2mm.nii.gz" ]; then
    echo "Creating pons binary mask..."
    fslmaths vois/voi_Pons_2mm.nii.gz -bin vois/voi_pons_binary.nii.gz
fi

echo -e "\nChecking created masks:"
for mask in vois/*_binary.nii.gz; do
    if [ -f "$mask" ]; then
        echo "$mask:"
        fslstats "$mask" -V
    fi
done
