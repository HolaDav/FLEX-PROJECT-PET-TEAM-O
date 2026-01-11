#!/bin/bash
# Normalize all PET files to consistent range
REF_CEREBELLAR=3.5  # Target cerebellar value

for subject in AD02 AD03 AD04 AD06 AD07 AD08 AD09 AD11; do
    PET_FILE="data/$subject/pet/${subject}_PiB_5070_MNI.nii.gz"
    if [ -f "$PET_FILE" ]; then
        CEREBELLAR=$(fslstats "$PET_FILE" -k vois/voi_cereb_binary.nii.gz -M 2>/dev/null)
        if [ -n "$CEREBELLAR" ] && (( $(echo "$CEREBELLAR > 5" | bc -l 2>/dev/null) )); then
            echo "Fixing $subject: cerebellar=$CEREBELLAR"
            SCALE=$(echo "$REF_CEREBELLAR / $CEREBELLAR" | bc -l)
            fslmaths "$PET_FILE" -mul $SCALE "data/$subject/pet/${subject}_PiB_5070_MNI_norm.nii.gz"
        fi
    fi
done
