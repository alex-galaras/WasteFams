#!/usr/bin/env bash
# Merge every chunk's metrics.tsv (Step 4) into the one combined metrics.tsv
# the rest of this pipeline (split_by_quality.sh onward) reads.
#
# Input:  $PROJECT_DIR/structures/af3_results/chunk_*/metrics.tsv
# Output: $PROJECT_DIR/structures/metrics.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

DIR="$PROJECT_DIR/structures"

first_chunk=$(ls "$DIR"/af3_results/chunk_*/metrics.tsv | head -1)
head -1 "$first_chunk" > "$DIR/metrics.tsv"
for f in "$DIR"/af3_results/chunk_*/metrics.tsv; do
  tail -n +2 "$f" >> "$DIR/metrics.tsv"
done

echo "Wrote $DIR/metrics.tsv"
