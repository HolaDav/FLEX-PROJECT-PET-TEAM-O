#!/bin/bash
echo "=== FINAL SUVR EXTRACTION ==="
echo "Using all reference regions from GAIN table"

mkdir -p final_results
OUTPUT="final_results/suvr_final_$(date +%Y%m%d).csv"
echo "Subject,Group,Reference,Cortical_Mean,Ref_Mean,SUVR,Processing_Date" > "$OUTPUT"

extract_for_subject() {
    local subject=$1
    local group=$2
    
    echo "Processing $subject..."
    
    # Find PET file
    PET_FILE=""
    for pet_file in "data/$subject/pet/${subject}_PiB_5070_MNI.nii.gz" \
                    "data/$subject/pet/${subject}_PiB_5070_MNI_thr.nii.gz"; do
        if [ -f "$pet_file" ]; then
            PET_FILE="$pet_file"
            echo "  Using: $(basename $PET_FILE)"
            break
        fi
    done
    
    if [ -z "$PET_FILE" ]; then
        echo "  ✗ No PET file found"
        return 1
    fi
    
    # Check PET statistics
    PET_STATS=$(fslstats "$PET_FILE" -R -M -S)
    echo "  PET range: $(echo $PET_STATS | awk '{print $1 "-" $2}')"
    
    # Define reference regions (from GAIN table)
    declare -A ref_regions=(
        ["CG"]="vois/voi_cereb_binary.nii.gz"    # Cerebellar Gray
        ["WC"]="vois/voi_wc_binary.nii.gz"       # Whole Cerebellum
        ["WC+B"]="vois/voi_wcbs_binary.nii.gz"   # Whole Cerebellum + Brainstem
        ["Pons"]="vois/voi_pons_binary.nii.gz"   # Pons
    )
    
    # Always use cortical mask
    CORTICAL_MASK="vois/voi_ctx_binary.nii.gz"
    
    if [ ! -f "$CORTICAL_MASK" ]; then
        echo "  ✗ Cortical mask not found!"
        return 1
    fi
    
    # Extract cortical value
    CORTICAL=$(fslstats "$PET_FILE" -k "$CORTICAL_MASK" -M 2>/dev/null)
    
    if [ -z "$CORTICAL" ]; then
        echo "  ✗ Cortical extraction failed"
        return 1
    fi
    
    echo "  Cortical mean: $CORTICAL"
    
    # Extract for each reference region
    for ref_name in "${!ref_regions[@]}"; do
        ref_mask="${ref_regions[$ref_name]}"
        
        if [ -f "$ref_mask" ]; then
            REF_MEAN=$(fslstats "$PET_FILE" -k "$ref_mask" -M 2>/dev/null)
            
            if [ -n "$REF_MEAN" ]; then
                SUVR=$(echo "$CORTICAL / $REF_MEAN" | bc -l 2>/dev/null)
                echo "  $ref_name: $REF_MEAN (SUVR: $SUVR)"
                echo "$subject,$group,$ref_name,$CORTICAL,$REF_MEAN,$SUVR,$(date +%Y-%m-%d)" >> "$OUTPUT"
            else
                echo "  $ref_name: Extraction failed"
            fi
        else
            echo "  $ref_name: Mask not found ($ref_mask)"
        fi
    done
    
    echo ""
}

# Process subjects
echo "=== TEST SUBJECTS ==="
for subject in AD01 AD02 AD03 AD20 AD21 YC101 YC104 YC105; do
    if [ -d "data/$subject" ]; then
        if [[ "$subject" == AD* ]]; then
            group="AD"
        else
            group="YC"
        fi
        extract_for_subject "$subject" "$group"
    fi
done

echo ""
echo "=== RESULTS ==="
echo "First few lines:"
head -20 "$OUTPUT"

echo ""
echo "=== SUMMARY ==="
echo "AD subjects should have SUVR_CG around: 1.2-3.0"
echo "YC subjects should have SUVR_CG around: 0.8-1.2"
