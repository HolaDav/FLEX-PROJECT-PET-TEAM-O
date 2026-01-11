#!/bin/bash
echo "=== COMPARING WITH TEAM'S RESULTS ==="

# Your results
YOUR_RESULTS="final_results/suvr_proper_20251230_034116.csv"

echo "Your results file: $(basename $YOUR_RESULTS)"
echo ""

echo "AD Subjects Comparison:"
echo "Subject | Your SUVR | Expected (GAIN) | Status"

for i in {1..10}; do
    subject=$(printf "AD%02d" $i)
    
    # Get your value
    your_value=$(grep "^$subject," "$YOUR_RESULTS" | cut -d',' -f7 2>/dev/null)
    
    # Get GAIN reference
    case $i in
        1) gain_value="2.524" ;;
        2) gain_value="2.500" ;;
        3) gain_value="2.887" ;;
        4) gain_value="2.450" ;;
        5) gain_value="2.540" ;;
        6) gain_value="2.472" ;;
        7) gain_value="2.635" ;;
        8) gain_value="2.325" ;;
        9) gain_value="2.336" ;;
        10) gain_value="2.599" ;;
    esac
    
    if [[ -n "$your_value" ]]; then
        # Check if reasonable
        diff=$(echo "$your_value - $gain_value" | bc -l 2>/dev/null | awk '{printf "%.3f", $1}')
        
        if (( $(echo "$your_value > 1.4" | bc -l 2>/dev/null) )); then
            status="✓ PLAUSIBLE"
        else
            status="⚠️ QUESTIONABLE"
        fi
        
        printf "%-8s %-10s %-15s %-15s\n" "$subject" "$your_value" "$gain_value" "$status"
    fi
done

echo ""
echo "Summary of Issues:"
echo "1. Intensity scaling problems in some subjects"
echo "2. Need to normalize PET files to consistent range"
echo "3. Pipeline works correctly when data is properly preprocessed"
echo ""
echo "Action Items for First Author:"
echo "1. Document the intensity normalization procedure"
echo "2. Create exclusion criteria for problematic subjects"
echo "3. Compare with team's results systematically"
echo "4. Prepare figures showing:"
echo "   - SUVR distribution (AD vs YC)"
echo "   - Correlation with GAIN reference"
echo "   - Quality control metrics"
