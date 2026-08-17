#!/usr/bin/env bash
# Split AlphaFold3 models into three quality tiers by pTM (column 3 of
# metrics.tsv).
#
# Input:  $PROJECT_DIR/structures/metrics.tsv
# Output: $PROJECT_DIR/structures/structures_results/HQ.tsv (pTM >= 0.70)
#         $PROJECT_DIR/structures/structures_results/MQ.tsv (0.50 <= pTM < 0.70)
#         $PROJECT_DIR/structures/structures_results/LQ.tsv (pTM < 0.50)
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

METRICS="$PROJECT_DIR/structures/metrics.tsv"
DIR="$PROJECT_DIR/structures/structures_results"
mkdir -p "$DIR"

awk -F'\t' 'NR==1 || $3 >= 0.70' "$METRICS" > "$DIR/HQ.tsv"
awk -F'\t' 'NR==1 || $3 >= 0.50 && $3 < 0.70' "$METRICS" > "$DIR/MQ.tsv"
awk -F'\t' 'NR==1 || $3 < 0.50' "$METRICS" > "$DIR/LQ.tsv"

echo "Wrote $DIR/{HQ,MQ,LQ}.tsv"
