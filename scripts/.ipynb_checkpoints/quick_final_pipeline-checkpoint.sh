#!/bin/bash
echo "========================================================================"
echo "QUICK FINAL PIPELINE - Get Results Now"
echo "Started: $(date)"
echo "========================================================================"

# Create output file
OUTPUT="final_results/FINAL_RESULTS_$(date +%Y%m%d_%H%M).csv"
echo "Subject,Group,Status,Cortical_Mean,Cerebellar_Mean,SUVR_CG,SUVR_WC,SUVR_Pons,Note" > "$OUTPUT"

# Function to extract with error handling
extract_quick() {
    local subject=$1
    local group=$2
    
    echo "Processing $subject ($group)..."
    
    # Find PET file
    PET_FILE=""
    for file in "data/$subject/pet/${subject}_PiB_5070_MNI.nii.gz" \
                "data/$subject/pet/${subject}_PiB_5070_MNI_thr.nii.gz"; do
        if [ -f "$file" ]; then
            PET_FILE="$file"
            break
        fi
    done
    
    if [ -z "$PET_FILE" ]; then
        echo "  ✗ No PET file"
        echo "$subject,$group,NO_PET,,,,,," >> "$OUTPUT"
        return
    fi
    
    # Extract cortical value
    CORTICAL=$(fslstats "$PET_FILE" -k vois/voi_ctx_binary.nii.gz -M 2>/dev/null)
    if [ -z "$CORTICAL" ]; then
        echo "  ✗ Cortical extraction failed"
        echo "$subject,$group,NO_CORTICAL,,,,,," >> "$OUTPUT"
        return
    fi
    
    # Extract for each reference region
    SUVR_CG=""; SUVR_WC=""; SUVR_Pons=""
    NOTE=""
    
    # 1. Cerebellar Gray (CG)
    if [ -f "vois/voi_cereb_binary.nii.gz" ]; then
        CEREBELLAR=$(fslstats "$PET_FILE" -k vois/voi_cereb_binary.nii.gz -M 2>/dev/null)
        if [ -n "$CEREBELLAR" ]; then
            SUVR_CG=$(echo "$CORTICAL / $CEREBELLAR" | bc -l 2>/dev/null)
            
            # Check for intensity issues
            if (( $(echo "$CEREBELLAR > 10" | bc -l 2>/dev/null) )); then
                NOTE="${NOTE}HIGH_CEREB_"
            fi
        fi
    fi
    
    # 2. Whole Cerebellum (WC)
    if [ -f "vois/voi_WhlCbl_2mm.nii" ]; then
        WC=$(fslstats "$PET_FILE" -k vois/voi_WhlCbl_2mm.nii -M 2>/dev/null)
        if [ -n "$WC" ]; then
            SUVR_WC=$(echo "$CORTICAL / $WC" | bc -l 2>/dev/null)
        fi
    fi
    
    # 3. Pons
    if [ -f "vois/voi_Pons_2mm.nii" ]; then
        PONS=$(fslstats "$PET_FILE" -k vois/voi_Pons_2mm.nii -M 2>/dev/null)
        if [ -n "$PONS" ]; then
            SUVR_Pons=$(echo "$CORTICAL / $PONS" | bc -l 2>/dev/null)
        fi
    fi
    
    # Determine status
    STATUS="OK"
    if [ -n "$SUVR_CG" ]; then
        if [ "$group" = "AD" ] && (( $(echo "$SUVR_CG < 1.4" | bc -l 2>/dev/null) )); then
            STATUS="CHECK_AD_LOW"
        elif [ "$group" = "YC" ] && (( $(echo "$SUVR_CG > 1.2" | bc -l 2>/dev/null) )); then
            STATUS="CHECK_YC_HIGH"
        fi
    fi
    
    echo "  Cortical: $CORTICAL, Cerebellar: $CEREBELLAR, SUVR_CG: $SUVR_CG ($STATUS)"
    echo "$subject,$group,$STATUS,$CORTICAL,$CEREBELLAR,$SUVR_CG,$SUVR_WC,$SUVR_Pons,$NOTE" >> "$OUTPUT"
}

# Process ALL subjects quickly
echo ""
echo "=== PROCESSING ALL SUBJECTS (Quick Mode) ==="

# AD subjects
for i in {1..25}; do
    SUBJ=$(printf "AD%02d" $i)
    if [ -d "data/$SUBJ" ]; then
        extract_quick "$SUBJ" "AD"
    fi
done

# YC subjects  
for i in {101..125}; do
    SUBJ=$(printf "YC%d" $i)
    if [ -d "data/$SUBJ" ]; then
        extract_quick "$SUBJ" "YC"
    fi
done

echo ""
echo "========================================================================"
echo "RESULTS SUMMARY"
echo "========================================================================"

echo ""
echo "Subjects with good SUVR_CG values:"
echo "AD > 1.4, YC < 1.2"
echo ""

echo "AD subjects with SUVR_CG > 1.4:"
grep ",AD," "$OUTPUT" | awk -F',' '{if ($6+0 > 1.4) printf "  %s: %.3f\n", $1, $6}'

echo ""
echo "YC subjects with SUVR_CG < 1.2:"
grep ",YC," "$OUTPUT" | awk -F',' '{if ($6+0 < 1.2) printf "  %s: %.3f\n", $1, $6}'

echo ""
echo "Problematic AD subjects (SUVR_CG < 1.4):"
grep ",AD," "$OUTPUT" | awk -F',' '{if ($6+0 < 1.4 && $6 != "") printf "  %s: %.3f (%s)\n", $1, $6, $3}'

echo ""
echo "Results saved to: $OUTPUT"
echo "Total subjects processed: $(($(wc -l < "$OUTPUT") - 1))"
