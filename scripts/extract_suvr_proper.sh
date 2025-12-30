#!/bin/bash
echo "=== PROPER SUVR EXTRACTION ==="
echo "Direct extraction - no unnecessary registration"

mkdir -p final_results
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT="final_results/suvr_proper_${TIMESTAMP}.csv"

# Create header
echo "Subject,Group,Analyst,Pipeline,Cortical_Mean,Cerebellar_Mean,SUVR,Processing_Date,QC_Status" > "$OUTPUT"

extract_proper() {
    local subject=$1
    local group=$2
    
    echo "Processing $subject..."
    
    # Use the main MNI-registered PET file (NOT thresholded)
    PET_FILE="data/$subject/pet/${subject}_PiB_5070_MNI.nii.gz"
    
    if [ ! -f "$PET_FILE" ]; then
        echo "  ⚠️  Main PET file not found, trying alternatives..."
        # Try other possible files in order of preference
        for pet_file in "data/$subject/pet/${subject}_PiB_5070_MNI_thr.nii.gz" \
                        "data/$subject/pet/${subject}_PiB_5070_T1.nii.gz"; do
            if [ -f "$pet_file" ]; then
                PET_FILE="$pet_file"
                break
            fi
        done
    fi
    
    if [ ! -f "$PET_FILE" ]; then
        echo "  ✗ No PET file found for $subject"
        echo "$subject,$group,David,FSL,,,,$(date +%Y-%m-%d),NO_PET_FILE" >> "$OUTPUT"
        return 1
    fi
    
    echo "  Using: $(basename $PET_FILE)"
    
    # Check PET file quality
    PET_MIN=$(fslstats "$PET_FILE" -l 0 -R 2>/dev/null | awk '{print $1}')
    PET_MAX=$(fslstats "$PET_FILE" -R 2>/dev/null | awk '{print $2}')
    PET_MEAN=$(fslstats "$PET_FILE" -M 2>/dev/null)
    
    echo "  PET range: $PET_MIN to $PET_MAX, mean: $PET_MEAN"
    
    # Define masks - use the ones that WORKED in manual test
    CORTICAL_MASK="vois/voi_ctx_binary.nii.gz"
    CEREBELLAR_MASK="vois/voi_cereb_binary.nii.gz"  # Cerebellar Gray
    
    # Check masks exist
    if [ ! -f "$CORTICAL_MASK" ] || [ ! -f "$CEREBELLAR_MASK" ]; then
        echo "  ✗ Masks not found!"
        echo "$subject,$group,David,FSL,,,,$(date +%Y-%m-%d),MASKS_MISSING" >> "$OUTPUT"
        return 1
    fi
    
    # DIRECT EXTRACTION - NO REGISTRATION
    echo "  Extracting values..."
    CORTICAL=$(fslstats "$PET_FILE" -k "$CORTICAL_MASK" -M 2>/dev/null)
    CEREBELLAR=$(fslstats "$PET_FILE" -k "$CEREBELLAR_MASK" -M 2>/dev/null)
    
    # Debug: check what we're getting
    echo "  Raw cortical: $CORTICAL"
    echo "  Raw cerebellar: $CEREBELLAR"
    
    if [ -z "$CORTICAL" ] || [ -z "$CEREBELLAR" ]; then
        echo "  ✗ Extraction failed (empty values)"
        echo "$subject,$group,David,FSL,,,,$(date +%Y-%m-%d),EXTRACTION_FAILED" >> "$OUTPUT"
        return 1
    fi
    
    # Calculate SUVR
    SUVR=$(echo "$CORTICAL / $CEREBELLAR" | bc -l 2>/dev/null)
    
    if [ -z "$SUVR" ]; then
        echo "  ✗ SUVR calculation failed"
        echo "$subject,$group,David,FSL,$CORTICAL,$CEREBELLAR,,$(date +%Y-%m-%d),SUVR_CALC_FAILED" >> "$OUTPUT"
        return 1
    fi
    
    # Quality Control
    QC_STATUS="PASS"
    
    # Check cerebellar range (PiB expected: 1-4)
    if (( $(echo "$CEREBELLAR < 0.5" | bc -l 2>/dev/null) )); then
        QC_STATUS="CEREBELLAR_TOO_LOW"
    elif (( $(echo "$CEREBELLAR > 10" | bc -l 2>/dev/null) )); then
        QC_STATUS="CEREBELLAR_TOO_HIGH"
    elif (( $(echo "$CEREBELLAR > 4" | bc -l 2>/dev/null) )); then
        QC_STATUS="CEREBELLAR_HIGH"
    fi
    
    # Check SUVR range
    if (( $(echo "$SUVR > 5" | bc -l 2>/dev/null) )); then
        QC_STATUS="SUVR_VERY_HIGH"
    elif (( $(echo "$SUVR < 0.5" | bc -l 2>/dev/null) )); then
        QC_STATUS="SUVR_VERY_LOW"
    fi
    
    # Check against expected ranges
    if [ "$group" = "AD" ]; then
        if (( $(echo "$SUVR < 1.2" | bc -l 2>/dev/null) )); then
            QC_STATUS="AD_BUT_LOW_SUVR"
        fi
    elif [ "$group" = "YC" ]; then
        if (( $(echo "$SUVR > 1.4" | bc -l 2>/dev/null) )); then
            QC_STATUS="YC_BUT_HIGH_SUVR"
        fi
    fi
    
    echo "  SUVR: $SUVR ($QC_STATUS)"
    
    # Save results
    echo "$subject,$group,David,FSL,$CORTICAL,$CEREBELLAR,$SUVR,$(date +%Y-%m-%d),$QC_STATUS" >> "$OUTPUT"
    
    echo ""
}

# Process ALL subjects
echo "=== PROCESSING AD SUBJECTS (01-25) ==="
for i in {1..25}; do
    SUBJ=$(printf "AD%02d" $i)
    if [ -d "data/$SUBJ" ]; then
        extract_proper "$SUBJ" "AD"
    fi
done

echo ""
# echo "=== PROCESSING YC SUBJECTS (101-125) ==="
# for i in {101..125}; do
    # SUBJ=$(printf "YC%d" $i)
    # if [ -d "data/$SUBJ" ]; then
        # extract_proper "$SUBJ" "YC"
    # fi
# done

echo ""
echo "=== FINAL RESULTS ==="
echo "Results saved to: $OUTPUT"
echo ""
echo "First 10 entries:"
head -11 "$OUTPUT"

echo ""
echo "=== SUMMARY STATISTICS ==="
echo "Total entries: $(($(wc -l < "$OUTPUT") - 1))"
echo ""
echo "QC Status breakdown:"
tail -n +2 "$OUTPUT" | cut -d',' -f9 | sort | uniq -c

echo ""
echo "AD vs YC comparison (average SUVR):"
echo "AD: $(tail -n +2 "$OUTPUT" | grep ",AD," | awk -F',' '{sum+=$7; count++} END {if(count>0) print sum/count; else print "N/A"}')"
echo "YC: $(tail -n +2 "$OUTPUT" | grep ",YC," | awk -F',' '{sum+=$7; count++} END {if(count>0) print sum/count; else print "N/A"}')"
