#!/bin/bash
echo "=== T-TEST CALCULATION ==="

# Your data
AD_MEAN=2.5347
AD_SD=0.1242
AD_N=3

YC_MEAN=1.0446
YC_SD=0.0901
YC_N=5

# Pooled variance
POOLED_VAR=$(echo "(($AD_N-1)*$AD_SD*$AD_SD + ($YC_N-1)*$YC_SD*$YC_SD) / ($AD_N + $YC_N - 2)" | bc -l)

# Standard error
SE=$(echo "sqrt($POOLED_VAR * (1/$AD_N + 1/$YC_N))" | bc -l)

# t-value
T_VAL=$(echo "($AD_MEAN - $YC_MEAN) / $SE" | bc -l)

# Degrees of freedom
DF=$((AD_N + YC_N - 2))

# Cohen's d (effect size)
COHENS_D=$(echo "($AD_MEAN - $YC_MEAN) / sqrt($POOLED_VAR)" | bc -l)

echo ""
echo "Independent samples t-test:"
echo "  t($DF) = $T_VAL"
echo "  Cohen's d = $COHENS_D (very large effect)"
echo ""
echo "Interpretation: Extremely large effect size confirms clear group separation."
