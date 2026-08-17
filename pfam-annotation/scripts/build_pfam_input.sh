#!/usr/bin/env bash
# Build the Pfam-search input: representative sequence for every family that
# passed HHfilter (Step 6 of protein-family-generation).
#
# Input:  $PROJECT_DIR/step3_protein_families/families_100.tsv,
#         $PROJECT_DIR/step2_deduplication_summary/total_sequences.tsv,
#         $PROJECT_DIR/step5_hhfilter/hhfilter_members.tsv
# Output: $PROJECT_DIR/analysisII_pfam/input_pfam.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

FAMILIES_REP="$PROJECT_DIR/step3_protein_families/families_100.tsv"
SEQUENCES="$PROJECT_DIR/step2_deduplication_summary/total_sequences.tsv"
MEMBERS="$PROJECT_DIR/step5_hhfilter/hhfilter_members.tsv"
DIR="$PROJECT_DIR/analysisII_pfam"
mkdir -p "$DIR"

join -t $'\t' -1 2 -2 1 "$FAMILIES_REP" "$SEQUENCES" \
  | awk '{print $2"\t"$1"\t"$4}' \
  | sort -k1,1 \
  > "$DIR/all.families.representatives.tsv"

# Restrict to families that passed HHfilter
cut -f1 "$MEMBERS" | sort -u > "$DIR/families_hhfilter.tsv"

join -t $'\t' -1 1 -2 1 "$DIR/families_hhfilter.tsv" "$DIR/all.families.representatives.tsv" \
  | sort -k1,1 \
  > "$DIR/input_pfam.tsv"

echo "Wrote $DIR/input_pfam.tsv"
