# FSL Pipeline for Team Testing
## Reproducibility Validation

## What Supervisors Want:
"Test the pipeline for reproducibility with the other team" - Philip

## Quick Test (10 minutes):
1. Place your data: data/AD01/pet/AD01_PiB_5070_MNI.nii.gz
2. Run: ./run_fsl_pipeline.sh
3. Compare results with your SPM pipeline

## Expected Outcome:
- FSL pipeline should produce SUVR values
- Compare FSL vs SPM for same subjects
- Note any differences (especially intensity scaling)

## Key Test Subjects:
Check these specifically (from your SPM results):
- sub-01: SPM SUVR=2.14, GAIN=2.10
- sub-05: SPM had intensity issues (cerebellar=17533!)
- sub-20: Good quality subject

## What to Report:
1. Does FSL pipeline run successfully?
2. Are SUVR values similar to SPM?
3. Does FSL detect the same intensity issues?
4. Overall reproducibility score

## For Abstract:
"We validated an open-source FSL pipeline against an established SPM implementation, demonstrating reproducibility across platforms (r=XX, n=XX subjects)."
