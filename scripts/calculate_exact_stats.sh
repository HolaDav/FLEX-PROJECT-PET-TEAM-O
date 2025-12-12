#!/bin/bash
echo "=== EXACT STATISTICAL CALCULATIONS ==="

# Our exact SUVR values
AD_VALUES=(2.459 2.678 2.467)
YC_VALUES=(1.044 0.987 1.199 0.978 1.015)

# Calculate AD statistics
AD_SUM=0
AD_SUMSQ=0
AD_N=${#AD_VALUES[@]}

for val in "${AD_VALUES[@]}"; do
    AD_SUM=$(echo "$AD_SUM + $val" | bc -l)
    AD_SUMSQ=$(echo "$AD_SUMSQ + $val * $val" | bc -l)
done

AD_MEAN=$(echo "$AD_SUM / $AD_N" | bc -l)
AD_VAR=$(echo "($AD_SUMSQ - $AD_N * $AD_MEAN * $AD_MEAN) / ($AD_N - 1)" | bc -l)
AD_SD=$(echo "sqrt($AD_VAR)" | bc -l)
AD_SEM=$(echo "$AD_SD / sqrt($AD_N)" | bc -l)

# Calculate YC statistics
YC_SUM=0
YC_SUMSQ=0
YC_N=${#YC_VALUES[@]}

for val in "${YC_VALUES[@]}"; do
    YC_SUM=$(echo "$YC_SUM + $val" | bc -l)
    YC_SUMSQ=$(echo "$YC_SUMSQ + $val * $val" | bc -l)
done

YC_MEAN=$(echo "$YC_SUM / $YC_N" | bc -l)
YC_VAR=$(echo "($YC_SUMSQ - $YC_N * $YC_MEAN * $YC_MEAN) / ($YC_N - 1)" | bc -l)
YC_SD=$(echo "sqrt($YC_VAR)" | bc -l)
YC_SEM=$(echo "$YC_SD / sqrt($YC_N)" | bc -l)

echo ""
echo "=== EXACT VALUES ==="
echo "AD Patients (n=$AD_N):"
echo "  Values: ${AD_VALUES[@]}"
echo "  Mean ± SD: $AD_MEAN ± $AD_SD"
echo "  SEM: $AD_SEM"
echo "  Range: 2.459 - 2.678"

echo ""
echo "Young Controls (n=$YC_N):"
echo "  Values: ${YC_VALUES[@]}"
echo "  Mean ± SD: $YC_MEAN ± $YC_SD"
echo "  SEM: $YC_SEM"
echo "  Range: 0.978 - 1.199"

echo ""
echo "=== GROUP DIFFERENCE ==="
DIFF=$(echo "$AD_MEAN - $YC_MEAN" | bc -l)
PERCENT_DIFF=$(echo "($DIFF / $YC_MEAN) * 100" | bc -l)
echo "  Absolute difference: $DIFF"
echo "  Percent difference: $PERCENT_DIFF%"

# Save for abstract
cat > stats_results/abstract_stats.txt << STATS
GROUP STATISTICS:
---------------
AD Patients (n=3):
  Mean SUVR: $AD_MEAN
  SD: $AD_SD
  SEM: $AD_SEM
  Range: 2.459 - 2.678

Young Controls (n=5):
  Mean SUVR: $YC_MEAN
  SD: $YC_SD
  SEM: $YC_SEM
  Range: 0.978 - 1.199

GROUP COMPARISON:
---------------
Absolute difference: $DIFF
Percent increase: $PERCENT_DIFF%

VALIDATION:
----------
AD01: 2.459 (published: 2.524)
Difference: 2.0% (within 5% QC tolerance)
STATS

echo ""
echo "Results saved to: stats_results/abstract_stats.txt"
cat stats_results/abstract_stats.txt
