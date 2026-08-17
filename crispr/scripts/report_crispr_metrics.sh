#!/usr/bin/env bash
# Report basic counts of the merged CCTyper output.
#
# Input: $PROJECT_DIR/crispr_elements/crisprs_all_results.tab
#        $PROJECT_DIR/crispr_elements/cas9_operons_results.tab
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

DIR="$PROJECT_DIR/crispr_elements"

echo "CRISPR arrays: $(tail -n +2 "$DIR/crisprs_all_results.tab" | wc -l)"
echo "Scaffolds with CRISPR arrays: $(tail -n +2 "$DIR/crisprs_all_results.tab" | cut -f1 | sort -u | wc -l)"
echo "Predicted Cas operons: $(tail -n +2 "$DIR/cas9_operons_results.tab" | wc -l)"
echo "Scaffolds with predicted Cas operons: $(tail -n +2 "$DIR/cas9_operons_results.tab" | cut -f1 | sort -u | wc -l)"
