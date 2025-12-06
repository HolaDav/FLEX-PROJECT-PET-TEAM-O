#!/bin/bash
echo "=== RE-EXTRACTING SUVR WITH IMPROVED ALIGNMENT ==="

mkdir -p results
echo "Subject,Group,Cortical_Mean,Cerebellar_Mean,SUVR,Notes" > results/suvr_improved.csv

MNI_TEMPLATE="/cvmfs/neurodesk.ardc.edu.au/containers/mrtrix3_3.0.1_20200908/mrtrix3_3.0.1_20200908.simg/opt/fsl-6.0.3/data/standard/MNI152_T1_2mm.nii.gz"

for SUBJECT in AD01 AD02 AD03 AD04 AD05 YC101 YC102 YC103 YC104 YC105; do
    PET_FILE="data/$SUBJECT/pet/${SUBJECT}_PiB_5070_MNI_thr.nii.gz"
    
    if [ ! -f "$PET_FILE" ]; then
        echo "$SUBJECT,SKIP,NA,NA,NA,Missing PET file" >> results/suvr_improved.csv
        continue
    fi
    
    # Determine group
    if [[ "$SUBJECT" == AD* ]]; then
        GROUP="AD"
    else
        GROUP="YC"
    fi
    
    echo "Processing $SUBJECT..."
    
    # Use improved registration for problematic subjects, original for others
    if [[ "$SUBJECT" == "AD02" || "$SUBJECT" == "AD04" ]]; then
        # Improved registration
        flirt -in "$MNI_TEMPLATE" \
              -ref "$PET_FILE" \
              -out "vois/MNI_to_${SUBJECT}_final.nii.gz" \
              -omat "vois/MNI_to_${SUBJECT}_final.mat" \
              -dof 12 -cost mutualinfo
        
        flirt -in vois/voi_ctx_binary.nii \
              -ref "$PET_FILE" \
              -out "vois/voi_ctx_${SUBJECT}_final.nii" \
              -applyxfm -init "vois/MNI_to_${SUBJECT}_final.mat" \
              -interp nearestneighbour
        
        flirt -in vois/voi_cereb_binary.nii \
              -ref "$PET_FILE" \
              -out "vois/voi_cereb_${SUBJECT}_final.nii" \
              -applyxfm -init "vois/MNI_to_${SUBJECT}_final.mat" \
              -interp nearestneighbour
        
        CTX_MASK="vois/voi_ctx_${SUBJECT}_final.nii"
        CEREB_MASK="vois/voi_cereb_${SUBJECT}_final.nii"
        NOTES="Improved alignment"
    else
        # Use original method (worked for these)
        CTX_MASK="vois/voi_ctx_${SUBJECT}.nii"
        CEREB_MASK="vois/voi_cereb_${SUBJECT}.nii"
        NOTES="Original alignment"
    fi
    
    # Extract values
    CORTICAL=$(fslstats "$PET_FILE" -k "$CTX_MASK" -M)
    CEREBELLAR=$(fslstats "$PET_FILE" -k "$CEREB_MASK" -M)
    
    if [ -z "$CORTICAL" ] || [ -z "$CEREBELLAR" ]; then
        echo "$SUBJECT,$GROUP,NA,NA,NA,Error extracting" >> results/suvr_improved.csv
        continue
    fi
    
    SUVR=$(echo "$CORTICAL / $CEREBELLAR" | bc -l)
    
    # Check if values are reasonable
    if [ $(echo "$CEREBELLAR < 1 || $CEREBELLAR > 15" | bc) -eq 1 ]; then
        NOTES="$NOTES (Unusual cerebellar: $CEREBELLAR)"
    fi
    
    echo "$SUBJECT,$GROUP,$CORTICAL,$CEREBELLAR,$SUVR,$NOTES" >> results/suvr_improved.csv
    echo "  $SUBJECT: SUVR=$SUVR, Cerebellar=$CEREBELLAR"
done

echo ""
echo "=== IMPROVED RESULTS ==="
cat results/suvr_improved.csv

echo ""
echo "=== GROUP STATISTICS ==="
echo "AD subjects SUVR:"
grep ",AD," results/suvr_improved.csv | cut -d',' -f5 | awk '{sum+=$1; count++} END{if(count>0) print "Mean:", sum/count, "N:", count}'

echo ""
echo "YC subjects SUVR:"
grep ",YC," results/suvr_improved.csv | cut -d',' -f5 | awk '{sum+=$1; count++} END{if(count>0) print "Mean:", sum/count, "N:", count}'
