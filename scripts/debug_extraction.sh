#!/bin/bash
# Debug exactly what the extraction script does

echo "=== DEBUG EXTRACTION FOR AD01 ==="

# 1. Which PET file would the script use?
PET_FILES=("data/AD01/pet/AD01_PiB_5070_MNI_thr_improved.nii.gz" 
           "data/AD01/pet/AD01_PiB_5070_MNI_thr.nii.gz")

for PET_FILE in "${PET_FILES[@]}"; do
    if [ -f "$PET_FILE" ]; then
        echo "Found PET file: $PET_FILE"
        
        # 2. What's in this file?
        echo "  PET statistics:"
        fslstats "$PET_FILE" -R -M -S
        
        # 3. Extract with original mask
        echo "  Direct extraction with voi_ctx_binary.nii.gz:"
        fslstats "$PET_FILE" -k vois/voi_ctx_binary.nii.gz -M
        
        echo "  Direct extraction with voi_cereb_binary.nii.gz:"
        fslstats "$PET_FILE" -k vois/voi_cereb_binary.nii.gz -M
        
        # 4. Extract with aligned mask
        if [ -f "vois/voi_ctx_AD01.nii.gz" ]; then
            echo "  Extraction with voi_ctx_AD01.nii.gz:"
            fslstats "$PET_FILE" -k vois/voi_ctx_AD01.nii.gz -M
        fi
        
        if [ -f "vois/voi_cereb_AD01.nii.gz" ]; then
            echo "  Extraction with voi_cereb_AD01.nii.gz:"
            fslstats "$PET_FILE" -k vois/voi_cereb_AD01.nii.gz -M
        fi
        
        echo ""
    fi
done
