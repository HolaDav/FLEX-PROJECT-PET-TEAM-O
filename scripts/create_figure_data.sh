#!/bin/bash
echo "=== CREATING FIGURE DATA ==="

# Create data for bar chart (can be used in Excel/R)
cat > stats_results/figure_data.csv << FIGDATA
Group,Subject,SUVR
AD,AD01,2.459
AD,AD03,2.678
AD,AD05,2.467
YC,YC101,1.044
YC,YC102,0.987
YC,YC103,1.199
YC,YC104,0.978
YC,YC105,1.015
FIGDATA

# Create summary for bar chart
cat > stats_results/group_summary.csv << SUMMARY
Group,Mean,SD,SEM,n
AD,2.535,0.111,0.064,3
YC,1.045,0.091,0.041,5
SUMMARY

echo "Figure data created:"
echo "1. Individual points: stats_results/figure_data.csv"
echo "2. Group summary: stats_results/group_summary.csv"
echo ""
echo "=== FIGURE SUGGESTIONS ==="
echo ""
echo "Figure 1: Group comparison bar chart"
echo "  - X-axis: AD vs YC groups"
echo "  - Y-axis: SUVR"
echo "  - Bars: Group means with error bars (SEM)"
echo "  - Overlay: Individual data points"
echo ""
echo "Figure 2: Pipeline validation"
echo "  - Scatter: Our AD01 vs Published AD01 (2.459 vs 2.524)"
echo "  - Reference line: y=x"
echo "  - QC boundary: ±5% lines"
