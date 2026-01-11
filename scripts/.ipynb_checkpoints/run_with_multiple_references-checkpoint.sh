#!/bin/bash
echo "=== TESTING MULTIPLE REFERENCE REGIONS ==="

# Test with different references
REFERENCES=("Cerebellar_Gray" "Whole_Cerebellum" "Pons")
REF_FILES=("vois/voi_cereb_binary.nii.gz" 
           "vois/voi_WhlCbl_2mm.nii" 
           "vois/voi_Pons_2mm.nii")

echo "Testing subject: AD01"
PET_FILE="data/AD01/pet/AD01_PiB_5070_MNI.nii.gz"

if [ -f "$PET_FILE" ]; then
    CORTICAL=$(fslstats "$PET_FILE" -k vois/voi_ctx_binary.nii.gz -M)
    
    for i in {0..2}; do
        REF_NAME="${REFERENCES[$i]}"
        REF_FILE="${REF_FILES[$i]}"
        
        if [ -f "$REF_FILE" ]; then
            REF_VAL=$(fslstats "$PET_FILE" -k "$REF_FILE" -M)
            if [ -n "$REF_VAL" ]; then
                SUVR=$(echo "$CORTICAL / $REF_VAL" | bc -l)
                echo "  $REF_NAME: SUVR = $SUVR (Ref value: $REF_VAL)"
            fi
        fi
    done
fi
