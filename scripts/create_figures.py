#!/usr/bin/env python3
"""
Create Figures for GAAIN Centiloid Pipeline
Creates Figure 1 with three panels for the abstract
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl

# Set style for scientific figures
mpl.rcParams['figure.figsize'] = [12, 4]
mpl.rcParams['font.size'] = 10
mpl.rcParams['font.family'] = 'sans-serif'
mpl.rcParams['font.sans-serif'] = ['Arial', 'DejaVu Sans']
mpl.rcParams['axes.linewidth'] = 1.5
mpl.rcParams['xtick.major.width'] = 1.5
mpl.rcParams['ytick.major.width'] = 1.5

# Create Figure 1 with 3 panels
fig = plt.figure(figsize=(15, 5))

# ================= PANEL A: PIPELINE FLOWCHART =================
ax1 = plt.subplot(1, 3, 1)
ax1.set_xlim(0, 10)
ax1.set_ylim(0, 10)
ax1.axis('off')
ax1.set_title('A. Pipeline Overview', fontsize=12, fontweight='bold', pad=20)

# Draw flowchart
# T1 Processing
ax1.text(2, 8, 'T1 MRI', fontweight='bold', ha='center', fontsize=10)
ax1.plot([2, 2], [7.5, 6.5], 'k-', linewidth=2)
ax1.text(2, 6, 'Skull-strip\n(BET)', ha='center', fontsize=9, 
         bbox=dict(boxstyle='round,pad=0.5', facecolor='lightblue', alpha=0.7))
ax1.plot([2, 2], [5.5, 4.5], 'k-', linewidth=2)
ax1.text(2, 4, 'Normalize to MNI\n(FLIRT, 12 DOF)', ha='center', fontsize=9,
         bbox=dict(boxstyle='round,pad=0.5', facecolor='lightblue', alpha=0.7))

# PET Processing
ax1.text(8, 8, 'PET (50-70min)', fontweight='bold', ha='center', fontsize=10)
ax1.plot([8, 8], [7.5, 6.5], 'k-', linewidth=2)
ax1.text(8, 6, 'Coregister to T1\n(FLIRT, 6 DOF)', ha='center', fontsize=9,
         bbox=dict(boxstyle='round,pad=0.5', facecolor='lightgreen', alpha=0.7))
ax1.plot([8, 8], [5.5, 4.5], 'k-', linewidth=2)
ax1.text(8, 4, 'Normalize to MNI\n(Concatenate transforms)', ha='center', fontsize=9,
         bbox=dict(boxstyle='round,pad=0.5', facecolor='lightgreen', alpha=0.7))

# VOI Processing
ax1.plot([2, 8], [3, 3], 'k--', linewidth=1, alpha=0.5)
ax1.text(5, 2.5, 'VOI Alignment\n(Affine to PET space)', ha='center', fontsize=9,
         bbox=dict(boxstyle='round,pad=0.5', facecolor='orange', alpha=0.7))
ax1.plot([5, 5], [2, 1.5], 'k-', linewidth=2)
ax1.text(5, 1, 'SUVR Calculation\n(Cortical / Cerebellar)', ha='center', fontsize=9,
         bbox=dict(boxstyle='round,pad=0.5', facecolor='red', alpha=0.7))

# ================= PANEL B: VALIDATION PLOT =================
ax2 = plt.subplot(1, 3, 2)
ax2.set_title('B. Pipeline Validation', fontsize=12, fontweight='bold', pad=20)

# Validation data
published = 2.524
our_value = 2.459
percent_diff = 2.0

# Create bar plot
categories = ['Published', 'Our Pipeline']
values = [published, our_value]
colors = ['gray', 'blue']

bars = ax2.bar(categories, values, color=colors, alpha=0.7, edgecolor='black', linewidth=1.5)
ax2.set_ylabel('SUVR', fontweight='bold')
ax2.set_ylim(0, 3.0)

# Add value labels on bars
for bar, value in zip(bars, values):
    height = bar.get_height()
    ax2.text(bar.get_x() + bar.get_width()/2., height + 0.05,
             f'{value:.3f}', ha='center', va='bottom', fontweight='bold')

# Add QC boundaries
ax2.axhline(y=published * 1.05, color='red', linestyle='--', alpha=0.5, linewidth=1)
ax2.axhline(y=published * 0.95, color='red', linestyle='--', alpha=0.5, linewidth=1)
ax2.text(1.5, published * 1.05 + 0.05, '5% QC boundary', fontsize=8, color='red', ha='right')

# Add difference text
ax2.text(0.5, 2.7, f'Difference: {percent_diff:.1f}%', 
         ha='center', fontweight='bold', fontsize=10,
         bbox=dict(boxstyle='round,pad=0.3', facecolor='lightyellow', alpha=0.9))

ax2.grid(True, alpha=0.3, linestyle='--')

# ================= PANEL C: GROUP COMPARISON =================
ax3 = plt.subplot(1, 3, 3)
ax3.set_title('C. Group Comparison', fontsize=12, fontweight='bold', pad=20)

# Group data
groups = ['AD Patients', 'Young Controls']
group_means = [2.535, 1.045]
group_sems = [0.0717, 0.0403]  # Standard Error of Mean
individual_data = [
    [2.459, 2.678, 2.467],  # AD individual values
    [1.044, 0.987, 1.199, 0.978, 1.015]  # YC individual values
]

# Colors
group_colors = ['red', 'blue']
individual_colors = ['darkred', 'darkblue']

# Plot bars with error bars (SEM)
x_pos = np.arange(len(groups))
bars = ax3.bar(x_pos, group_means, yerr=group_sems, 
               capsize=10, alpha=0.6, color=group_colors,
               edgecolor='black', linewidth=1.5)

# Plot individual data points with jitter
for i, (data, color) in enumerate(zip(individual_data, individual_colors)):
    # Add jitter to x positions
    jitter = np.random.normal(0, 0.05, size=len(data))
    ax3.scatter(np.full(len(data), i) + jitter, data, 
                color=color, s=60, alpha=0.7, edgecolor='black', linewidth=1, zorder=10)

# Add threshold line
ax3.axhline(y=1.4, color='green', linestyle='--', linewidth=2, alpha=0.7, label='Amyloid+ threshold')
ax3.text(1.5, 1.42, 'SUVR > 1.4', color='green', fontsize=9, ha='right')

# Add percentage increase
percent_increase = 142.6
ax3.text(0.5, 2.3, f'{percent_increase:.0f}% increase', 
         ha='center', fontweight='bold', fontsize=10,
         bbox=dict(boxstyle='round,pad=0.3', facecolor='lightyellow', alpha=0.9))

# Set labels and ticks
ax3.set_xticks(x_pos)
ax3.set_xticklabels(groups, fontweight='bold')
ax3.set_ylabel('SUVR', fontweight='bold')
ax3.set_ylim(0, 3.0)
ax3.legend(loc='upper right', fontsize=9)
ax3.grid(True, alpha=0.3, linestyle='--')

# Add sample size labels
for i, (mean, sem, n) in enumerate(zip(group_means, group_sems, [3, 5])):
    ax3.text(i, mean + sem + 0.1, f'n={n}', ha='center', fontsize=9, fontweight='bold')

plt.tight_layout()
plt.savefig('figures/figure1_pipeline_results.png', dpi=300, bbox_inches='tight')
plt.savefig('figures/figure1_pipeline_results.pdf', bbox_inches='tight')
print("Figure 1 saved to: figures/figure1_pipeline_results.png and .pdf")
plt.show()
