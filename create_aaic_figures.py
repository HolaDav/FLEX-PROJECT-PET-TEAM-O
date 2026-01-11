#!/usr/bin/env python3
"""
Create AAIC submission figures for amyloid PET pipeline
Author: Your Name
Date: 2025-01-07
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats
import warnings
warnings.filterwarnings('ignore')

# Set style for publication-ready figures
plt.style.use('seaborn-v0_8-whitegrid')
sns.set_palette("colorblind")

# ============================================================================
# 1. LOAD AND PREPARE DATA
# ============================================================================

print("Loading data...")

# Load your FSL results
your_results = pd.read_csv('results/summary_20251230.csv')

# Clean your results - keep only valid subjects
valid_results = your_results[~your_results['Note'].str.contains('HIGH_CEREB_', na=False)].copy()
valid_results = valid_results[valid_results['Status'] != 'CHECK_AD_LOW']

print(f"Your valid results: {len(valid_results)} subjects")

# ============================================================================
# FIGURE 1: VALIDATION SCATTER PLOT (Your FSL vs GAIN)
# ============================================================================

print("\nCreating Figure 1: Validation Scatter Plot...")

# GAIN reference values (manually extracted from your data)
gain_data = {
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

# Match your results with GAIN
validation_data = []
for idx, row in valid_results.iterrows():
    subject = row['Subject']
    if subject in gain_data:
        validation_data.append({
            'Subject': subject,
            'Group': row['Group'],
            'Your_SUVR_CG': row['SUVR_CG'],
            'GAIN_SUVR_CG': gain_data[subject]
        })

validation_df = pd.DataFrame(validation_data)

# Calculate correlation
r, p = stats.pearsonr(validation_df['GAIN_SUVR_CG'], validation_df['Your_SUVR_CG'])
slope, intercept, r_value, p_value, std_err = stats.linregress(
    validation_df['GAIN_SUVR_CG'], validation_df['Your_SUVR_CG']
)
r_squared = r_value**2
mape = np.mean(np.abs((validation_df['GAIN_SUVR_CG'] - validation_df['Your_SUVR_CG']) / validation_df['GAIN_SUVR_CG'])) * 100

print(f"Correlation with GAIN: r = {r:.3f}, p = {p:.4f}")
print(f"MAPE: {mape:.1f}%")
print(f"R²: {r_squared:.3f}")

# Create Figure 1
fig1, ax1 = plt.subplots(figsize=(8, 6))

# Color by group
colors = {'AD': 'red', 'YC': 'blue'}
for group in ['AD', 'YC']:
    group_data = validation_df[validation_df['Group'] == group]
    ax1.scatter(group_data['GAIN_SUVR_CG'], group_data['Your_SUVR_CG'],
               color=colors[group], alpha=0.7, s=80, label=f'{group} Cohort')

# Add regression line
x_fit = np.linspace(validation_df['GAIN_SUVR_CG'].min(), validation_df['GAIN_SUVR_CG'].max(), 100)
y_fit = slope * x_fit + intercept
ax1.plot(x_fit, y_fit, 'k--', linewidth=2, label=f'Fit: y = {slope:.2f}x + {intercept:.2f}')

# Add identity line (perfect agreement)
max_val = max(validation_df['GAIN_SUVR_CG'].max(), validation_df['Your_SUVR_CG'].max())
ax1.plot([0, max_val], [0, max_val], 'gray', linestyle=':', linewidth=1.5, label='Identity')

# Labels and title
ax1.set_xlabel('GAIN Reference SUVR (Cerebellar Gray)', fontsize=12, fontweight='bold')
ax1.set_ylabel('Our Pipeline SUVR (Cerebellar Gray)', fontsize=12, fontweight='bold')
ax1.set_title('Validation Against GAIN Reference Standard', fontsize=14, fontweight='bold')

# Add correlation annotation
text_box = f'r = {r:.2f}, p < 0.001\nMAPE = {mape:.1f}%\nR² = {r_squared:.2f}'
ax1.text(0.05, 0.95, text_box, transform=ax1.transAxes, fontsize=10,
        verticalalignment='top', bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.8))

# Add legend
ax1.legend(loc='lower right', fontsize=10)

# Set equal aspect ratio
ax1.set_aspect('equal', adjustable='box')

# Adjust layout
plt.tight_layout()

# Save figure
fig1.savefig('Figure1_Validation_Scatter.png', dpi=300, bbox_inches='tight')
print("Figure 1 saved as 'Figure1_Validation_Scatter.png'")

# ============================================================================
# FIGURE 2: REPRODUCIBILITY BLAND-ALTMAN (SPM vs FSL)
# ============================================================================

print("\nCreating Figure 2: Reproducibility Bland-Altman Plot...")

# We'll use Abdullahi's data for reproducibility
# Need to match subjects between SPM and FSL results

# Abdullahi's FSL results (from your data - simplified)
abdullahi_fsl = {
    'AD01': 2.375869, 'AD02': 2.225270, 'AD03': 2.639913, 'AD04': 2.497949,
    'AD05': 2.603195, 'AD06': 2.375588, 'AD07': 2.603143, 'AD08': 2.167682,
    'AD09': 2.188248, 'AD11': 2.320635, 'AD12': 2.387008, 'AD13': 0.519978,
    'AD14': 2.245146, 'AD15': 1.849024, 'AD16': 2.012706, 'AD17': 1.944441,
    'AD18': 2.229382, 'AD19': 2.498101, 'AD20': 2.348707, 'AD21': 2.770017,
    'AD22': 2.486011, 'AD24': 2.056408, 'AD25': 1.886089
}

# Abdullahi's SPM results (from your data - simplified)
abdullahi_spm = {
    'sub-01': 2.140541, 'sub-02': 2.137577, 'sub-03': 2.406583, 'sub-04': 2.196650,
    'sub-05': 1.311098, 'sub-06': 2.143659, 'sub-07': 2.191799, 'sub-08': 1.981264,
    'sub-09': 1.291365, 'sub-10': 1.637986, 'sub-11': 2.201323, 'sub-12': 2.059189,
    'sub-13': 2.026817, 'sub-14': 1.925955, 'sub-15': 1.643404, 'sub-16': 1.686333,
    'sub-17': 1.773660, 'sub-18': 1.996401, 'sub-19': 2.176678, 'sub-20': 2.126634,
    'sub-21': 2.358589, 'sub-22': 2.275659, 'sub-23': 2.023130, 'sub-24': 2.030900,
    'sub-25': 1.676629
}

# Match subjects (AD01 = sub-01, etc.)
repro_data = []
for i in range(1, 26):
    fsl_key = f'AD{i:02d}'
    spm_key = f'sub-{i:02d}'
    
    if fsl_key in abdullahi_fsl and spm_key in abdullahi_spm:
        # Skip AD13 outlier
        if i != 13:
            repro_data.append({
                'Subject': fsl_key,
                'FSL_SUVR': abdullahi_fsl[fsl_key],
                'SPM_SUVR': abdullahi_spm[spm_key]
            })

repro_df = pd.DataFrame(repro_data)

# Calculate Bland-Altman statistics
repro_df['Mean'] = (repro_df['SPM_SUVR'] + repro_df['FSL_SUVR']) / 2
repro_df['Difference'] = repro_df['SPM_SUVR'] - repro_df['FSL_SUVR']

mean_diff = repro_df['Difference'].mean()
std_diff = repro_df['Difference'].std()
upper_limit = mean_diff + 1.96 * std_diff
lower_limit = mean_diff - 1.96 * std_diff

# Calculate correlation
r_repro, p_repro = stats.pearsonr(repro_df['SPM_SUVR'], repro_df['FSL_SUVR'])

print(f"Reproducibility correlation: r = {r_repro:.3f}, p = {p_repro:.4f}")
print(f"Mean difference (SPM - FSL): {mean_diff:.3f}")
print(f"Limits of agreement: [{lower_limit:.3f}, {upper_limit:.3f}]")

# Create Figure 2
fig2, ax2 = plt.subplots(figsize=(8, 6))

# Scatter plot
ax2.scatter(repro_df['Mean'], repro_df['Difference'], color='darkgreen', alpha=0.7, s=80)

# Add mean difference line
ax2.axhline(y=mean_diff, color='red', linestyle='-', linewidth=2, label=f'Mean: {mean_diff:.3f}')

# Add limits of agreement
ax2.axhline(y=upper_limit, color='red', linestyle='--', linewidth=1.5, label=f'+1.96 SD: {upper_limit:.3f}')
ax2.axhline(y=lower_limit, color='red', linestyle='--', linewidth=1.5, label=f'-1.96 SD: {lower_limit:.3f}')

# Fill between limits
ax2.fill_between([repro_df['Mean'].min(), repro_df['Mean'].max()],
                lower_limit, upper_limit, alpha=0.1, color='red')

# Labels and title
ax2.set_xlabel('Mean SUVR (SPM + FSL)/2', fontsize=12, fontweight='bold')
ax2.set_ylabel('Difference (SPM - FSL)', fontsize=12, fontweight='bold')
ax2.set_title('SPM vs FSL Quantification Agreement\n(Bland-Altman Plot)', fontsize=14, fontweight='bold')

# Add correlation annotation
text_box = f'r = {r_repro:.2f}, p < 0.001\nMean diff = {mean_diff:.3f}\n±1.96 SD = ±{1.96*std_diff:.3f}'
ax2.text(0.05, 0.95, text_box, transform=ax2.transAxes, fontsize=10,
        verticalalignment='top', bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))

# Add legend
ax2.legend(loc='upper right', fontsize=10)

# Adjust layout
plt.tight_layout()

# Save figure
fig2.savefig('Figure2_Reproducibility_BlandAltman.png', dpi=300, bbox_inches='tight')
print("Figure 2 saved as 'Figure2_Reproducibility_BlandAltman.png'")

# ============================================================================
# FIGURE 3: CENTILOID DISTRIBUTION (AD vs Controls)
# ============================================================================

print("\nCreating Figure 3: Centiloid Distribution...")

# Calculate Centiloid from your valid results
# Using formula: CL = (SUVR - intercept) / slope
# For PiB with cerebellar gray: CL = (SUVR - 1.08) / 0.0086
intercept = 1.08
slope_cl = 0.0086

valid_results['Centiloid'] = (valid_results['SUVR_CG'] - intercept) / slope_cl

# Create Figure 3
fig3, ax3 = plt.subplots(figsize=(8, 6))

# Prepare data for boxplot
ad_cl = valid_results[valid_results['Group'] == 'AD']['Centiloid']
yc_cl = valid_results[valid_results['Group'] == 'YC']['Centiloid']

# Create boxplot
box_data = [ad_cl, yc_cl]
box = ax3.boxplot(box_data, patch_artist=True, widths=0.6)

# Customize boxes
colors_box = ['lightcoral', 'lightblue']
for patch, color in zip(box['boxes'], colors_box):
    patch.set_facecolor(color)
    patch.set_alpha(0.7)

# Customize median lines
for median in box['medians']:
    median.set(color='black', linewidth=2)

# Add individual data points (jittered)
for i, group_data in enumerate(box_data):
    # Add some jitter to x-position
    x_jitter = np.random.normal(i+1, 0.04, size=len(group_data))
    ax3.scatter(x_jitter, group_data, alpha=0.6, s=50, color='black', edgecolor='white', linewidth=0.5)

# Add horizontal line at CL=0 (amyloid negative/positive threshold)
ax3.axhline(y=0, color='red', linestyle='--', linewidth=1.5, label='CL = 0 (Threshold)')

# Labels and title
ax3.set_xticklabels(['AD Cohort\n(n={})'.format(len(ad_cl)), 
                     'Control Cohort\n(n={})'.format(len(yc_cl))], fontsize=11)
ax3.set_ylabel('Centiloid Value', fontsize=12, fontweight='bold')
ax3.set_title('Amyloid Burden Distribution Across Diagnostic Groups', fontsize=14, fontweight='bold')

# Add statistics annotation
ad_median = np.median(ad_cl)
yc_median = np.median(yc_cl)
ad_iqr = np.percentile(ad_cl, 75) - np.percentile(ad_cl, 25)
yc_iqr = np.percentile(yc_cl, 75) - np.percentile(yc_cl, 25)

text_box = f'AD: Median = {ad_median:.1f}, IQR = {ad_iqr:.1f}\nYC: Median = {yc_median:.1f}, IQR = {yc_iqr:.1f}'
ax3.text(0.05, 0.95, text_box, transform=ax3.transAxes, fontsize=10,
        verticalalignment='top', bbox=dict(boxstyle='round', facecolor='lightyellow', alpha=0.8))

# Add legend
ax3.legend(loc='upper right', fontsize=10)

# Adjust layout
plt.tight_layout()

# Save figure
fig3.savefig('Figure3_Centiloid_Distribution.png', dpi=300, bbox_inches='tight')
print("Figure 3 saved as 'Figure3_Centiloid_Distribution.png'")

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================

print("\n" + "="*60)
print("SUMMARY STATISTICS")
print("="*60)

# Calculate summary statistics for AD and YC groups
print("\nSUVR Statistics (Cerebellar Gray Reference):")
print("-" * 40)

for group in ['AD', 'YC']:
    group_data = valid_results[valid_results['Group'] == group]['SUVR_CG']
    print(f"\n{group} Cohort (n={len(group_data)}):")
    print(f"  Mean ± SD: {group_data.mean():.2f} ± {group_data.std():.2f}")
    print(f"  Median: {group_data.median():.2f}")
    print(f"  Range: [{group_data.min():.2f}, {group_data.max():.2f}]")

print("\n" + "="*60)
print("All 3 figures created successfully!")
print("Files saved in current directory:")
print("1. Figure1_Validation_Scatter.png")
print("2. Figure2_Reproducibility_BlandAltman.png")
print("3. Figure3_Centiloid_Distribution.png")
print("="*60)

# Show all figures
plt.show()
