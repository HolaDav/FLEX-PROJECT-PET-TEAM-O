#!/bin/bash
echo "=== SIMPLE SUVR EXTRACTION ==="
echo "No registration - assuming PET is in MNI space"

mkdir -p final_results
OUTPUT="final_results/suvr_simple_$(date +%Y%m%d).csv"
echo "Subject,Group,Cortical_Mean,Cerebellar_Mean,SUVR,Processing_Date,Note" > "$OUTPUT"

extract_simple() {
    local subject=$1
    local group=$2
    
    echo "Processing $subject..."
    
    # Use the standard MNI-registered PET file (non-thresholded)
    PET_FILE="data/$subject/pet/${subject}_PiB_5070_MNI.nii.gz"
    
    if [ ! -f "$PET_FILE" ]; then
        echo "  ✗ $PET_FILE not found"
        # Try thresholded version
        PET_FILE="data/$subject/pet/${subject}_PiB_5070_MNI_thr.nii.gz"
        if [ ! -f "$PET_FILE" ]; then
            echo "  ✗ No PET file found"
            return 1
        fi
        echo "  Using thresholded version"
    else
        echo "  Using: $(basename $PET_FILE)"
    fi
    
    # Extract directly - NO REGISTRATION
    CORTICAL=$(fslstats "$PET_FILE" -k vois/voi_ctx_binary.nii.gz -M 2>/dev/null)
    CEREBELLAR=$(fslstats "$PET_FILE" -k vois/voi_cereb_binary.nii.gz -M 2>/dev/null)
    
    if [ -z "$CORTICAL" ] || [ -z "$CEREBELLAR" ]; then
        echo "  ✗ Extraction failed"
        echo "$subject,$group,,,,$(date +%Y-%m-%d),EXTRACTION_FAILED" >> "$OUTPUT"
        return 1
    fi
    
    SUVR=$(echo "$CORTICAL / $CEREBELLAR" | bc -l 2>/dev/null)
    
    # Quality checks
    NOTE="OK"
    if (( $(echo "$SUVR < 0.8" | bc -l 2>/dev/null) )); then
        NOTE="UNUSUALLY_LOW"
    elif (( $(echo "$SUVR > 3.5" | bc -l 2>/dev/null) )); then
        NOTE="UNUSUALLY_HIGH"
    fi
    
    echo "  Cortical: $CORTICAL"
    echo "  Cerebellar: $CEREBELLAR"
    echo "  SUVR: $SUVR ($NOTE)"
    
    echo "$subject,$group,$CORTICAL,$CEREBELLAR,$SUVR,$(date +%Y-%m-%d),$NOTE" >> "$OUTPUT"
    echo ""
}

# Process all subjects
echo "=== AD SUBJECTS ==="
for i in {1..25}; do
    SUBJ=$(printf "AD%02d" $i)
    if [ -d "data/$SUBJ" ]; then
        extract_simple "$SUBJ" "AD"
    fi
done

echo "=== YC SUBJECTS ==="
for i in {101..125}; do
    SUBJ=$(printf "YC%d" $i)
    if [ -d "data/$SUBJ" ]; then
        extract_simple "$SUBJ" "YC"
    fi
done

echo ""
echo "=== RESULTS SUMMARY ==="
echo "Expected ranges:"
echo "  AD: 1.2-3.0"
echo "  YC: 0.8-1.2"
echo ""
echo "Results saved to: $OUTPUT"
tail -n +2 "$OUTPUT" | awk -F',' '{printf "%-10s %-5s %-8s\n", $1, $2, $5}'
