#!/bin/bash
echo "=== EXTRACTING SUVR FOR ALL SUBJECTS ==="
echo ""

# Create results directory
mkdir -p results

# Header for CSV
echo "Subject,Group,Cortical_Mean,Cerebellar_Mean,SUVR" > results/all_suvr_results.csv

# Process each subject
for SUBJECT in AD01 AD02 AD03 AD04 AD05 YC101 YC102 YC103 YC104 YC105; do
    PET_FILE="data/$SUBJECT/pet/${SUBJECT}_PiB_5070_MNI_thr.nii.gz"
    
    if [ ! -f "$PET_FILE" ]; then
        echo "Skipping $SUBJECT - PET file not found"
        continue
    fi
    
    echo "Processing $SUBJECT..."
    
    # Determine group
    if [[ "$SUBJECT" == AD* ]]; then
        GROUP="AD"
    else
        GROUP="YC"
    fi
    
    # Align VOIs to this subject's PET
    flirt -in "/cvmfs/neurodesk.ardc.edu.au/containers/mrtrix3_3.0.1_20200908/mrtrix3_3.0.1_20200908.simg/opt/fsl-6.0.3/data/standard/MNI152_T1_2mm.nii.gz" \
          -ref "$PET_FILE" \
          -out "vois/MNI_to_${SUBJECT}.nii.gz" \
          -omat "vois/MNI_to_${SUBJECT}.mat" \
          -dof 6 2>/dev/null
    
    flirt -in vois/voi_ctx_binary.nii \
          -ref "$PET_FILE" \
          -out "vois/voi_ctx_${SUBJECT}.nii" \
          -applyxfm -init "vois/MNI_to_${SUBJECT}.mat" \
          -interp nearestneighbour 2>/dev/null
    
    flirt -in vois/voi_cereb_binary.nii \
          -ref "$PET_FILE" \
          -out "vois/voi_cereb_${SUBJECT}.nii" \
          -applyxfm -init "vois/MNI_to_${SUBJECT}.mat" \
          -interp nearestneighbour 2>/dev/null
    
    # Extract values
    CORTICAL=$(fslstats "$PET_FILE" -k "vois/voi_ctx_${SUBJECT}.nii" -M)
    CEREBELLAR=$(fslstats "$PET_FILE" -k "vois/voi_cereb_${SUBJECT}.nii" -M)
    
    if [ -z "$CORTICAL" ] || [ -z "$CEREBELLAR" ]; then
        echo "  Error extracting values for $SUBJECT"
        continue
    fi
    
    SUVR=$(echo "$CORTICAL / $CEREBELLAR" | bc -l)
    
    # Save to CSV
    echo "$SUBJECT,$GROUP,$CORTICAL,$CEREBELLAR,$SUVR" >> results/all_suvr_results.csv
    
    echo "  $SUBJECT: SUVR = $SUVR (Cortical: $CORTICAL, Cerebellar: $CEREBELLAR)"
done

echo ""
echo "=== RESULTS ==="
cat results/all_suvr_results.csv

echo ""
echo "=== GROUP SUMMARIES ==="
echo "AD subjects:"
grep ",AD," results/all_suvr_results.csv | cut -d',' -f5 | awk '{sum+=$1; count++} END{print "Mean SUVR:", sum/count}'

echo ""
echo "YC subjects:"
grep ",YC," results/all_suvr_results.csv | cut -d',' -f5 | awk '{sum+=$1; count++} END{print "Mean SUVR:", sum/count}'
