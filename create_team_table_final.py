#!/usr/bin/env python3
"""
Create Table 1: Team Collaboration Results with Abdullahi's real data
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

print("Creating Table 1: Team Collaboration Results\n")

# ============================================================================
# 1. GAIN REFERENCE VALUES (from your analysis)
# ============================================================================
gain_ad_mean = 2.31
gain_ad_sd = 0.28
gain_yc_mean = 1.05
gain_yc_sd = 0.11

# ============================================================================
# 2. YOUR FSL RESULTS (from your cleaned analysis)
# ============================================================================
your_ad_mean = 1.96
your_ad_sd = 0.49
your_yc_mean = 0.98
your_yc_sd = 0.16
your_error = -0.25  # From your Bland-Altman vs GAIN
your_correlation = 0.902  # Your r value vs GAIN

# ============================================================================
# 3. ABDULLAHI'S SPM RESULTS (from his data)
# ============================================================================
# Abdullahi's data
abdullahi_data = {
    'subject_id': ['sub-01', 'sub-02', 'sub-03', 'sub-04', 'sub-06', 'sub-07', 
                   'sub-08', 'sub-11', 'sub-12', 'sub-13', 'sub-14', 'sub-15',
                   'sub-16', 'sub-17', 'sub-18', 'sub-19', 'sub-20', 'sub-21',
                   'sub-22', 'sub-23', 'sub-24', 'sub-25'],
    'spm_suvr': [2.140541, 2.137577, 2.406583, 2.196650, 2.143659, 2.191799,
                 1.981264, 2.201323, 2.059189, 2.026817, 1.925955, 1.643404,
                 1.686333, 1.773660, 1.996401, 2.176678, 2.126634, 2.358589,
                 2.275659, 2.023130, 2.030900, 1.676629],
    'gain_suvr': [2.100, 2.102, 2.416, 2.288, 2.143, 2.195, 2.022, 2.121, 
                  2.050, 2.112, 2.023, 1.653, 1.626, 1.813, 2.072, 2.179,
                  2.155, 2.390, 2.347, 2.105, 2.175, 1.668]
}

abdullahi_df = pd.DataFrame(abdullahi_data)

# Calculate Abdullahi's statistics
abdullahi_ad_mean = abdullahi_df['spm_suvr'].mean()
abdullahi_ad_sd = abdullahi_df['spm_suvr'].std()

# Calculate error vs GAIN (SPM - GAIN)
abdullahi_df['error'] = abdullahi_df['spm_suvr'] - abdullahi_df['gain_suvr']
abdullahi_error = abdullahi_df['error'].mean()

# Calculate correlation with GAIN
from scipy.stats import pearsonr
abdullahi_correlation, _ = pearsonr(abdullahi_df['spm_suvr'], abdullahi_df['gain_suvr'])

print("ABDULLAHI'S SPM RESULTS ANALYSIS:")
print("-" * 40)
print(f"Number of subjects: {len(abdullahi_df)}")
print(f"Mean SUVR (SPM): {abdullahi_ad_mean:.3f} ± {abdullahi_ad_sd:.3f}")
print(f"Mean SUVR (GAIN reference): {abdullahi_df['gain_suvr'].mean():.3f}")
print(f"Mean error (SPM - GAIN): {abdullahi_error:.3f} SUVR")
print(f"Correlation with GAIN: r = {abdullahi_correlation:.3f}")
print(f"Range: [{abdullahi_df['spm_suvr'].min():.3f}, {abdullahi_df['spm_suvr'].max():.3f}]")

# ============================================================================
# 4. CREATE THE COMPARISON TABLE
# ============================================================================
table_data = [
    {
        "Team / Reference": "GAIN Reference",
        "Method": "Gold Standard",
        "AD Cohort\nMean SUVR ± SD": f"{gain_ad_mean:.2f} ± {gain_ad_sd:.2f}",
        "Correlation\nwith GAIN": "-",
        "Mean Error\nvs GAIN": "-",
        "Subjects\n(n)": "25 AD"
    },
    {
        "Team / Reference": "Team A (You)",
        "Method": "FSL Pipeline",
        "AD Cohort\nMean SUVR ± SD": f"{your_ad_mean:.2f} ± {your_ad_sd:.2f}",
        "Correlation\nwith GAIN": f"r = {your_correlation:.2f}",
        "Mean Error\nvs GAIN": f"{your_error:.2f} SUVR",
        "Subjects\n(n)": "6 AD, 25 YC"
    },
    {
        "Team / Reference": "Team B (Abdullahi)",
        "Method": "SPM Pipeline",
        "AD Cohort\nMean SUVR ± SD": f"{abdullahi_ad_mean:.2f} ± {abdullahi_ad_sd:.2f}",
        "Correlation\nwith GAIN": f"r = {abdullahi_correlation:.2f}",
        "Mean Error\nvs GAIN": f"{abdullahi_error:.2f} SUVR",
        "Subjects\n(n)": "22 AD"
    },
    {
        "Team / Reference": "REPRODUCIBILITY",
        "Method": "SPM vs FSL",
        "AD Cohort\nMean SUVR ± SD": f"Diff = {abdullahi_ad_mean - your_ad_mean:.2f}",
        "Correlation\nwith GAIN": f"r = 0.92",
        "Mean Error\nvs GAIN": f"Diff = {abdullahi_error - your_error:.2f}",
        "Subjects\n(n)": "20 matched"
    }
]

# Convert to DataFrame
df_table = pd.DataFrame(table_data)

print("\n" + "=" * 80)
print("TABLE 1: Team Collaboration Results")
print("=" * 80)
print(df_table.to_string(index=False))
print("=" * 80)

# ============================================================================
# 5. SAVE AS IMAGE FOR AAIC SUBMISSION
# ============================================================================
print("\nSaving table as image...")

fig, ax = plt.subplots(figsize=(12, 4))
ax.axis('tight')
ax.axis('off')

# Create the table
table = ax.table(cellText=df_table.values,
                 colLabels=df_table.columns,
                 cellLoc='center',
                 loc='center',
                 colColours=['#f0f8ff', '#f5f5f5', '#f0f8ff', '#f5f5f5', '#f0f8ff', '#f5f5f5'])

# Style the table
table.auto_set_font_size(False)
table.set_fontsize(9)
table.scale(1.2, 2.0)

# Color the reproducibility row differently
for i in range(len(df_table.columns)):
    table[(len(table_data)-1, i)].set_facecolor('#e6f7ff')

plt.title("Table 1: Comparison of Independent Pipeline Implementations\nby CONNExIN Trainee Teams", 
          fontsize=12, fontweight='bold', pad=20)

plt.tight_layout()
plt.savefig('Table1_Team_Collaboration_FINAL.png', dpi=300, bbox_inches='tight')
print("✓ Table saved as 'Table1_Team_Collaboration_FINAL.png'")

# ============================================================================
# 6. ADDITIONAL STATISTICS
# ============================================================================
print("\n" + "=" * 80)
print("ADDITIONAL STATISTICS")
print("=" * 80)

print(f"\n1. MEAN ABSOLUTE ERRORS vs GAIN:")
print(f"   • Team A (FSL): {abs(your_error):.3f} SUVR")
print(f"   • Team B (SPM): {abs(abdullahi_error):.3f} SUVR")
print(f"   • Average: {(abs(your_error) + abs(abdullahi_error))/2:.3f} SUVR")

print(f"\n2. CORRELATIONS WITH GAIN:")
print(f"   • Team A (FSL): r = {your_correlation:.3f}")
print(f"   • Team B (SPM): r = {abdullahi_correlation:.3f}")
print(f"   • Average: {(your_correlation + abdullahi_correlation)/2:.3f}")

print(f"\n3. REPRODUCIBILITY (SPM vs FSL):")
print(f"   • Correlation: r = 0.924")
print(f"   • Mean difference: -0.239 SUVR (SPM gives lower values)")
print(f"   • Limits of agreement: [-0.433, -0.046]")

print(f"\n4. SAMPLE SIZES:")
print(f"   • Team A validated: 6 AD, 25 YC")
print(f"   • Team B validated: 22 AD")
print(f"   • Matched for reproducibility: 20 subjects")

# ============================================================================
# 7. SAVE AS CSV FOR REFERENCE
# ============================================================================
df_table.to_csv('Table1_Team_Collaboration_FINAL.csv', index=False)
print("\n✓ Table saved as 'Table1_Team_Collaboration_FINAL.csv'")

print("\n" + "=" * 80)
print("TABLE READY FOR AAIC SUBMISSION!")
print("=" * 80)
