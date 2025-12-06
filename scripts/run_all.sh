#!/bin/bash
cd ~/Desktop/workspace

echo "1. Running preprocessing..."
./scripts/run_gaain_pipeline.sh 2>&1 | tee logs/preprocessing.log

echo ""
echo "2. Processing VOIs..."
./scripts/process_vois.sh 2>&1 | tee logs/vois.log

echo ""
echo "3. Calculating SUVR for AD01..."
./scripts/calculate_suvr.sh AD01 2>&1 | tee logs/suvr_ad01.log

echo ""
echo "4. Calculating SUVR for YC101..."
./scripts/calculate_suvr.sh YC101 2>&1 | tee logs/suvr_yc101.log

echo ""
echo "5. Quality check for AD01..."
./scripts/quality_check.sh AD01 2>&1 | tee logs/qc_ad01.log

echo ""
echo "========================================"
echo "All done! Check logs/ directory"
echo "========================================"
