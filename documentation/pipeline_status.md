# Amyloid PET Processing Pipeline - Status Report

## Current Status
- **Pipeline**: FSL-based SUVR extraction for PiB PET
- **Data**: 25 AD subjects, 25 YC subjects from GAIN dataset
- **Reference**: Cerebellar Gray (CG) from GAIN Supplementary Table 1
- **Current Issues**: Inconsistent SUVR values due to intensity scaling problems

## Key Findings
1. **Pipeline works correctly** for properly normalized PET data
2. **SUVR values match expected ranges** when data is consistent:
   - AD01: SUVR = 2.18 ✓ (Expected: 1.8-3.0)
   - AD05: SUVR = 2.32 ✓
   - AD20: SUVR = 2.50 ✓
3. **Problematic subjects** show intensity scaling issues:
   - AD02: Cortical mean = 531 (should be ~3-15)
   - AD04: Cerebellar mean = 11.79 (should be ~1-4)
   - AD07: SUVR = 0.58 (impossible for AD)

## Immediate Action Plan
1. **Identify and fix intensity scaling** in problematic PET files
2. **Implement quality control** to flag outliers
3. **Compare with GAIN reference values** for validation
4. **Document pipeline thoroughly** for collaboration

## Success Metrics
- AD subjects should have SUVR > 1.4 (amyloid positive)
- YC subjects should have SUVR < 1.2 (amyloid negative)
- SUVR values should correlate with GAIN reference (r > 0.8)
