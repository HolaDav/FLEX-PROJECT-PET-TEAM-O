#!/bin/bash
echo "=== EXTRACT SUVR FOR ALL SUBJECTS ==="
echo "Including newly processed subjects"
echo ""

MNI_TEMPLATE="/cvmfs/neurodesk.ardc.edu.au/containers/mrtrix3_3.0.1_20200908/mrtrix3_3.0.1_20200908.simg/opt/fsl-6.0.3/data/standard/MNI152_T1_2mm.nii.gz"

# Create comprehensive results file
mkdir -p final_results
echo "Subject,Group,Analyst,Pipeline,Cortical_Mean,Cerebellar_Mean,SUVR,Processing_Date,QC_Status" > final_results/all_fsl_results.csv

extract_suvr() {
    local subject=$1
    local group=$2
    
    echo "Processing $subject..."
    
    # Try different possible file names (improved vs regular)
    PET_FILE=""
    for pet_file in "data/$subject/pet/${subject}_PiB_5070_MNI_thr_improved.nii.gz" \
                    "data/$subject/pet/${subject}_PiB_5070_MNI_thr.nii.gz"; do
        if [ -f "$pet_file" ]; then
            PET_FILE="$pet_file"
            break
        fi
    done
    
    if [ -z "$PET_FILE" ]; then
        echo "  ✗ No PET file found for $subject"
        return 1
    fi
    
    echo "  Using: $(basename $PET_FILE)"
    
    # Align VOIs if not already done
    if [ ! -f "vois/voi_ctx_${subject}.nii.gz" ] || [ ! -f "vois/voi_cereb_${subject}.nii.gz" ]; then
        echo "  Aligning VOIs..."
        flirt -in "$MNI_TEMPLATE" \
            -ref "$PET_FILE" \
            -omat "vois/MNI_to_${subject}_new.mat" \
            -dof 6 2>/dev/null
        
        flirt -in vois/voi_ctx_binary.nii \
            -ref "$PET_FILE" \
            -out "vois/voi_ctx_${subject}.nii.gz" \
            -applyxfm -init "vois/MNI_to_${subject}_new.mat" \
            -interp nearestneighbour 2>/dev/null
        
        flirt -in vois/voi_cereb_binary.nii \
            -ref "$PET_FILE" \
            -out "vois/voi_cereb_${subject}.nii.gz" \
            -applyxfm -init "vois/MNI_to_${subject}_new.mat" \
            -interp nearestneighbour 2>/dev/null
    fi
    
    # Extract values
    CORTICAL=$(fslstats "$PET_FILE" -k "vois/voi_ctx_${subject}.nii.gz" -M 2>/dev/null)
    CEREBELLAR=$(fslstats "$PET_FILE" -k "vois/voi_cereb_${subject}.nii.gz" -M 2>/dev/null)
    
    # Quality check
    QC_STATUS="PASS"
    if [ -z "$CORTICAL" ] || [ -z "$CEREBELLAR" ]; then
        QC_STATUS="EXTRACTION_FAILED"
        SUVR=""
    else
        # Check cerebellar range (PiB should be 1-4)
        if (( $(echo "$CEREBELLAR < 0.5" | bc -l 2>/dev/null) )); then
            QC_STATUS="CEREBELLAR_TOO_LOW"
        elif (( $(echo "$CEREBELLAR > 10" | bc -l 2>/dev/null) )); then
            QC_STATUS="CEREBELLAR_TOO_HIGH"
        elif (( $(echo "$CEREBELLAR > 4" | bc -l 2>/dev/null) )); then
            QC_STATUS="CEREBELLAR_HIGH"
        fi
        
        # Calculate SUVR
        SUVR=$(echo "$CORTICAL / $CEREBELLAR" | bc -l 2>/dev/null)
        
        # Check SUVR range
        if [ -n "$SUVR" ]; then
            if (( $(echo "$SUVR > 3" | bc -l 2>/dev/null) )); then
                QC_STATUS="SUVR_VERY_HIGH"
            elif (( $(echo "$SUVR < 0.5" | bc -l 2>/dev/null) )); then
                QC_STATUS="SUVR_VERY_LOW"
            fi
        fi
    fi
    
    # Special notes
    NOTES=""
    if [ "$subject" = "AD02" ]; then
        NOTES="Intensity_scaled"
    fi
    
    # Save results
    echo "$subject,$group,David,FSL,$CORTICAL,$CEREBELLAR,$SUVR,$(date +%Y-%m-%d),$QC_STATUS" >> final_results/all_fsl_results.csv
    
    echo "  SUVR: $SUVR ($QC_STATUS)"
}

# Process all AD subjects (01-25 if available)
echo "=== PROCESSING AD SUBJECTS ==="
for i in {1..25}; do
    SUBJ=$(printf "AD%02d" $i)
    if [ -d "data/$SUBJ" ]; then
        extract_suvr "$SUBJ" "AD"
    fi
done

echo ""
echo "=== PROCESSING YC SUBJECTS ==="
for i in {1..25}; do
    SUBJ=$(printf "YC1%02d" $i)
    if [ -d "data/$SUBJ" ]; then
        extract_suvr "$SUBJ" "YC"
    fi
done

echo ""
echo "=== FINAL RESULTS ==="
cat final_results/all_fsl_results.csv

echo ""
echo "=== SUMMARY ==="
echo "Total subjects processed: $(wc -l < final_results/all_fsl_results.csv)"
echo "AD subjects: $(grep -c ",AD," final_results/all_fsl_results.csv)"
echo "YC subjects: $(grep -c ",YC," final_results/all_fsl_results.csv)"
echo ""
echo "QC Status breakdown:"
cut -d',' -f9 final_results/all_fsl_results.csv | sort | uniq -c
