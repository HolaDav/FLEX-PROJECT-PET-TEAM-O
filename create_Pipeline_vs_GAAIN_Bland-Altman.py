#!/usr/bin/env python3
"""
Create NEW Figure 2B: Bland-Altman for Your Pipeline vs GAAIN
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats

# Set style
plt.style.use('seaborn-v0_8-whitegrid')

print("Creating NEW Figure 2B: Pipeline vs GAAIN Bland-Altman...")

# Load your cleaned validation data (from earlier script)
# Assuming you have validation_df from previous analysis
# If not, recreate it:

# Your cleaned results
your_results = pd.read_csv('results/summary_20251230.csv')
valid_results = your_results[~your_results['Note'].str.contains('HIGH_CEREB_', na=False)].copy()
valid_results = valid_results[valid_results['Status'] != 'CHECK_AD_LOW']
problematic_fsl = ['AD05', 'AD09', 'AD10', 'AD13']
valid_results = valid_results[~valid_results['Subject'].isin(problematic_fsl)]

# GAAIN reference values
gaain_data = {
    'AD01': 2.524, 'AD02': 2.500, 'AD03': 2.887, 'AD04': 2.450, 'AD05': 2.540,
    'AD06': 2.472, 'AD07': 2.635, 'AD08': 2.325, 'AD09': 2.336, 'AD10': 2.599,
    'AD11': 2.376, 'AD12': 2.432, 'AD13': 2.509, 'AD14': 2.315, 'AD15': 1.955,
    'AD16': 1.898, 'AD17': 2.029, 'AD18': 2.348, 'AD19': 2.586, 'AD20': 2.446,
    'AD21': 2.851, 'AD22': 2.730, 'AD23': 2.521, 'AD24': 2.508, 'AD25': 1.933,
    'YC101': 1.131, 'YC102': 1.176, 'YC103': 1.105, 'YC104': 1.119, 'YC105': 1.134,
    'YC106': 1.206, 'YC107': 1.309, 'YC108': 1.257, 'YC109': 1.174, 'YC110': 1.226,
    'YC111': 1.196, 'YC112': 1.246, 'YC113': 1.162, 'YC114': 1.182, 'YC115': 1.125,
    'YC116': 1.110, 'YC117': 1.124, 'YC118': 1.060, 'YC119': 1.223, 'YC120': 1.183,
    'YC121': 1.141, 'YC122': 1.119, 'YC123': 1.103, 'YC124': 1.137, 'YC125': 1.149
}

# Create validation dataframe
validation_data = []
for idx, row in valid_results.iterrows():
    subject = row['Subject']
    if subject in gaain_data:
        validation_data.append({
            'Subject': subject,
            'Group': row['Group'],
            'Your_SUVR_CG': row['SUVR_CG'],
            'GAAIN_SUVR_CG': gaain_data[subject]
        })

validation_df = pd.DataFrame(validation_data)

# Calculate Bland-Altman for Your Pipeline vs GAAIN
validation_df['Mean_SUVR'] = (validation_df['Your_SUVR_CG'] + validation_df['GAAIN_SUVR_CG']) / 2
validation_df['Diff_SUVR'] = validation_df['Your_SUVR_CG'] - validation_df['GAAIN_SUVR_CG']  # Your - GAAIN

mean_diff = validation_df['Diff_SUVR'].mean()
std_diff = validation_df['Diff_SUVR'].std()
upper_limit = mean_diff + 1.96 * std_diff
lower_limit = mean_diff - 1.96 * std_diff

# Calculate correlation (for comparison)
r, p = stats.pearsonr(validation_df['GAAIN_SUVR_CG'], validation_df['Your_SUVR_CG'])

print(f"Your Pipeline vs GAAIN:")
print(f"  Mean difference (Your - GAAIN): {mean_diff:.3f}")
print(f"  Limits of agreement: [{lower_limit:.3f}, {upper_limit:.3f}]")
print(f"  Correlation: r = {r:.3f}, p = {p:.4f}")
print(f"  MAPE: {np.mean(np.abs(validation_df['Diff_SUVR']/validation_df['GAAIN_SUVR_CG']))*100:.1f}%")

# Create Figure 2B
fig, ax = plt.subplots(figsize=(8, 6))

# Color by group
colors = {'AD': 'red', 'YC': 'blue'}
for group in ['AD', 'YC']:
    group_data = validation_df[validation_df['Group'] == group]
    ax.scatter(group_data['Mean_SUVR'], group_data['Diff_SUVR'],
              color=colors[group], alpha=0.7, s=80, label=f'{group} Cohort')

# Add mean difference line
ax.axhline(y=mean_diff, color='darkred', linestyle='-', linewidth=2, label=f'Mean: {mean_diff:.3f}')

# Add limits of agreement
ax.axhline(y=upper_limit, color='darkred', linestyle='--', linewidth=1.5, label=f'+1.96 SD: {upper_limit:.3f}')
ax.axhline(y=lower_limit, color='darkred', linestyle='--', linewidth=1.5, label=f'-1.96 SD: {lower_limit:.3f}')

# Fill between limits
ax.fill_between([validation_df['Mean_SUVR'].min(), validation_df['Mean_SUVR'].max()],
               lower_limit, upper_limit, alpha=0.1, color='red')

# Add zero line (perfect agreement)
ax.axhline(y=0, color='black', linestyle=':', linewidth=1, alpha=0.5, label='Perfect Agreement')

# Labels and title
ax.set_xlabel('Mean SUVR (Your Pipeline + GAAIN)/2', fontsize=12, fontweight='bold')
ax.set_ylabel('Difference (Your Pipeline - GAAIN)', fontsize=12, fontweight='bold')
ax.set_title('Agreement with GAAIN Reference Standard\n(Bland-Altman Plot)', fontsize=14, fontweight='bold')

# Add statistics annotation
text_box = f'r = {r:.2f}\nMean diff = {mean_diff:.3f}\n±1.96 SD = ±{1.96*std_diff:.3f}\nn = {len(validation_df)}'
ax.text(0.05, 0.95, text_box, transform=ax.transAxes, fontsize=10,
       verticalalignment='top', bbox=dict(boxstyle='round', facecolor='lightyellow', alpha=0.8))

# Add legend
ax.legend(loc='upper right', fontsize=10)

# Adjust layout
plt.tight_layout()

# Save figure
fig.savefig('Figure2B_Pipeline_vs_GAAIN_BlandAltman.png', dpi=300, bbox_inches='tight')
print("\nFigure 2B saved as 'Figure2B_Pipeline_vs_GAAIN_BlandAltman.png'")

# Show figure
plt.show()

# ==============================================
# OPTIONAL: Create a combined figure (2A + 2B)
# ==============================================
print("\nCreating combined Figure 2 (A+B)...")

# Load SPM vs FSL data (from Abdullahi's results)
# This would need the actual data files
# For now, creating a placeholder

fig_combined, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))

# Left: SPM vs FSL (Existing Figure 2)
# You would load actual SPM vs FSL data here
ax1.text(0.5, 0.5, 'SPM vs FSL Bland-Altman\n(Reproducibility)\nr = 0.92', 
         transform=ax1.transAxes, ha='center', va='center', fontsize=12)
ax1.set_xlabel('Mean SUVR (SPM + FSL)/2', fontsize=11)
ax1.set_ylabel('Difference (SPM - FSL)', fontsize=11)
ax1.set_title('A) Method Reproducibility: SPM vs FSL', fontsize=12, fontweight='bold')

# Right: Pipeline vs GAAIN (New Figure 2B - using real data)
for group in ['AD', 'YC']:
    group_data = validation_df[validation_df['Group'] == group]
    ax2.scatter(group_data['Mean_SUVR'], group_data['Diff_SUVR'],
               color=colors[group], alpha=0.7, s=60, label=f'{group} Cohort')

ax2.axhline(y=mean_diff, color='darkred', linestyle='-', linewidth=2)
ax2.axhline(y=upper_limit, color='darkred', linestyle='--', linewidth=1.5)
ax2.axhline(y=lower_limit, color='darkred', linestyle='--', linewidth=1.5)
ax2.axhline(y=0, color='black', linestyle=':', linewidth=1, alpha=0.5)
ax2.fill_between([validation_df['Mean_SUVR'].min(), validation_df['Mean_SUVR'].max()],
                lower_limit, upper_limit, alpha=0.1, color='red')

ax2.set_xlabel('Mean SUVR (Pipeline + GAAIN)/2', fontsize=11)
ax2.set_ylabel('Difference (Pipeline - GAAIN)', fontsize=11)
ax2.set_title('B) Validation: Pipeline vs GAAIN Reference', fontsize=12, fontweight='bold')

# Add simplified annotation
ax2.text(0.05, 0.95, f'r = {r:.2f}\nMean diff = {mean_diff:.3f}', 
        transform=ax2.transAxes, fontsize=9,
        verticalalignment='top', bbox=dict(boxstyle='round', facecolor='lightyellow', alpha=0.8))

ax2.legend(loc='upper right', fontsize=9)

plt.suptitle('Bland-Altman Analyses: Reproducibility and Validation', 
             fontsize=14, fontweight='bold', y=1.02)
plt.tight_layout()
plt.savefig('Figure2_Combined_BlandAltman.png', dpi=300, bbox_inches='tight')
print("Combined Figure 2 saved as 'Figure2_Combined_BlandAltman.png'")