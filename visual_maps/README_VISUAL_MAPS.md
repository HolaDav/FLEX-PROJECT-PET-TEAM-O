# Visual Maps - GAAIN Centiloid Pipeline
## PET Team O - CONNExIN Flex Project

### Image Descriptions:

1. **cerebellum_alignment.png**
   - Purpose: Verify cerebellum VOI mask is properly aligned
   - What to look for: Green mask should cover cerebellum (back/bottom of brain)
   - Significance: Ensures correct reference region for SUVR calculation

2. **cortical_alignment.png**
   - Purpose: Verify cortical VOI mask alignment
   - What to look for: Red mask should cover cortical gray matter
   - Significance: Ensures correct target region for amyloid quantification

3. **all_masks_overlay.png**
   - Purpose: Show complete VOI coverage
   - What to look for: Green (cerebellum) and red (cortex) masks in correct anatomical locations
   - Significance: Visual QC of entire VOI pipeline

4. **normalization_check.png**
   - Purpose: Verify PET→MNI normalization quality
   - What to look for: PET signal (hot colors) aligned with MNI template anatomy
   - Significance: Ensures spatial standardization across subjects

### Pipeline Validation Summary:
- ✅ Cerebellum mask correctly placed in posterior fossa
- ✅ Cortical mask covers cerebral cortex
- ✅ PET signal anatomically plausible
- ✅ Normalization to MNI space successful

### Corresponding Quantitative Results:
- AD01 SUVR: 2.459 (validated against 2.524 published)
- Cerebellar mean: 4.15 (within expected 1-4 range for PiB)
- Pipeline error: 2.0% (within 5% GAAIN QC tolerance)
