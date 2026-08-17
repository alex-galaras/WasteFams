#!/usr/bin/env bash
# Merge CCTyper's per-chunk CRISPR array and Cas operon predictions into two
# repository-wide tables.
#
# Input:  $PROJECT_DIR/crispr_elements/cctyper_output/*/crisprs_all.tab
#         $PROJECT_DIR/crispr_elements/cctyper_output/*/cas_operons.tab
# Output: $PROJECT_DIR/crispr_elements/crisprs_all_results.tab
#         $PROJECT_DIR/crispr_elements/cas9_operons_results.tab
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

CCTYPER_OUT="$PROJECT_DIR/crispr_elements/cctyper_output"
OUT="$PROJECT_DIR/crispr_elements"

# Merge all CRISPR arrays
first_dir=$(ls -d "$CCTYPER_OUT"/*/ | head -1)
head -1 "${first_dir}crisprs_all.tab" > "$OUT/crisprs_all_results.tab"
for dir in "$CCTYPER_OUT"/*/
do
  tail -n +2 "${dir}crisprs_all.tab" >> "$OUT/crisprs_all_results.tab"
done

# Merge all Cas operon predictions
head -1 "${first_dir}cas_operons.tab" > "$OUT/cas9_operons_results.tab"
for dir in "$CCTYPER_OUT"/*/
do
  tail -n +2 "${dir}cas_operons.tab" >> "$OUT/cas9_operons_results.tab"
done

echo "Wrote $OUT/crisprs_all_results.tab and $OUT/cas9_operons_results.tab"
