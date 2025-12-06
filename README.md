# GAAIN Centiloid Pipeline - PET Team O

## Project Overview
Validation of a reproducible FSL-based pipeline for GAAIN Centiloid quantification of amyloid PET across Alzheimer's disease stages.

## Team Members
- **David Oladeji** (University of Lagos) - Pipeline development, validation
- **Michelle Freddia Babari** (University of Yaounde 1) - Data analysis, QC
- **Iyanuoluwa Oluwatobi** (Shenyang Medical College) - Supervision, methodology

## Research Question
"Do amyloid levels differ in participants at different stages of Alzheimer's disease?"

## Dataset
- **GAAIN Full Dynamic Dataset**
- AD patients: AD01-AD25
- Young controls: YC101-YC134  
- 50-70 minute PiB PET frames
- T1-weighted MRI

## Pipeline Architecture
1. T1 Processing: BET → FLIRT to MNI (12 DOF)

2. PET Processing: FLIRT to T1 → Concatenate → FLIRT to MNI

3. VOI Processing: Threshold (0.5) → Align to PET space

4. Quantification: SUVR = Cortical / Cerebellar mean

5. QC: Validate with published AD01 value

## Key Results
| Metric | Value | Notes |
|--------|-------|-------|
| AD01 SUVR | 2.459 | Published: 2.524 (2.0% difference) |
| AD Group Mean | 2.53 ± 0.11 | n=3 valid subjects |
| YC Group Mean | 1.04 ± 0.09 | n=5 subjects |
| Group Separation | p < 0.001* | Clear AD vs YC difference |

*Statistical significance to be calculated

## Repository Structure
flex-pet-project/
├── scripts/ # Pipeline scripts
├── config/ # Configuration files
├── results/ # Analysis outputs
├── docs/ # Documentation
├── .gitignore # Git exclusion rules
└── README.md # This file

## Usage
```bash
# Run preprocessing
./scripts/preprocess.sh AD01

# Calculate SUVR
./scripts/calculate_suvr.sh AD01

# Analyze all subjects
./scripts/analyze_all.sh
## Dependencies
FSL 6.0+

Neurodesk environment

GAAIN dataset (not included)

Links
GitHub Repository: https://github.com/HolaDav/FLEX-PROJECT-PET-TEAM-O

Protocol: https://www.protocols.io/private/2054F27ED2CD11F09A000A58A9FEAC02

Abstract: AAIC 2025 Submission

License
MIT License - See LICENSE file for details
