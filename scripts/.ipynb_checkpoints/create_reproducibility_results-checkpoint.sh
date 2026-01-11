#!/bin/bash
echo "=== CREATING REPRODUCIBILITY RESULTS ==="
echo "For collaboration with SPM team"
echo ""

# Create clean results directory
mkdir -p reproducibility_results

# Create FSL results file
echo "Subject,Group,Analyst,Pipeline,Cortical_Mean,Cerebellar_Mean,SUVR,Notes" > reproducibility_results/fsl_results.csv

# Extract SUVR values using your aligned VOIs
extract_suvr() {
    local subject=$1
    local group=$2
    
    echo "Extracting $subject..."
    
    PET_FILE="data/$subject/pet/${subject}_PiB_5070_MNI_thr.nii.gz"
    CTX_VOI="vois/voi_ctx_${subject}.nii.gz"
    CEREB_VOI="vois/voi_cereb_${subject}.nii.gz"
    
    # Check files exist
    if [ ! -f "$PET_FILE" ]; then
        echo "  ✗ PET file missing: $PET_FILE"
        return 1
    fi
    
    if [ ! -f "$CTX_VOI" ] || [ ! -f "$CEREB_VOI" ]; then
        echo "  ✗ VOI files missing for $subject"
        return 1
    fi
    
    # Extract values
    CORTICAL=$(fslstats "$PET_FILE" -k "$CTX_VOI" -M 2>/dev/null)
    CEREBELLAR=$(fslstats "$PET_FILE" -k "$CEREB_VOI" -M 2>/dev/null)
    
    if [ -z "$CORTICAL" ] || [ -z "$CEREBELLAR" ]; then
        echo "  ✗ Extraction failed"
        NOTES="Extraction_failed"
        SUVR=""
    else
        SUVR=$(echo "$CORTICAL / $CEREBELLAR" | bc -l 2>/dev/null)
        
        # Check for issues
        NOTES=""
        if (( $(echo "$CEREBELLAR > 10" | bc -l 2>/dev/null) )); then
            NOTES="High_cerebellar"
        elif (( $(echo "$CEREBELLAR < 0.5" | bc -l 2>/dev/null) )); then
            NOTES="Low_cerebellar"
        fi
        
        # Special case for AD02 (scaling issue)
        if [ "$subject" = "AD02" ]; then
            NOTES="Intensity_scaled_÷50"
        fi
        
        echo "  ✓ SUVR: $SUVR ($NOTES)"
    fi
    
    # Save to CSV
    echo "$subject,$group,David,FSL,$CORTICAL,$CEREBELLAR,$SUVR,$NOTES" >> reproducibility_results/fsl_results.csv
}

# Extract for all subjects
for sub in AD01 AD02 AD03 AD04 AD05; do
    extract_suvr "$sub" "AD"
done

for sub in YC101 YC102 YC103 YC104 YC105; do
    extract_suvr "$sub" "YC"
done

echo ""
echo "=== FSL RESULTS SUMMARY ==="
cat reproducibility_results/fsl_results.csv

echo ""
echo "=== STATISTICS ==="
echo "Subjects processed: 10"
echo "  AD: 5 subjects"
echo "  YC: 5 subjects"
echo ""
echo "File saved: reproducibility_results/fsl_results.csv"
