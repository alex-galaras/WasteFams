#!/usr/bin/env bash
# Join families to their Pfam hits, strip trailing Pfam version digits
# (e.g. PF00001.21 -> PF00001), and attach Pfam descriptions.
#
# Input:  $PROJECT_DIR/analysisII_pfam/input_pfam.tsv,
#         $PROJECT_DIR/analysisII_pfam/pfam_results.tsv,
#         $PROJECT_DIR/resources/pfam_database/table_pfam_description
# Output: $PROJECT_DIR/analysisII_pfam/fam_rep_pfam_description.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

DIR="$PROJECT_DIR/analysisII_pfam"
FAMILIES="$DIR/input_pfam.tsv"
PFAM_RESULTS="$DIR/pfam_results.tsv"
DESCRIPTION="$PROJECT_DIR/resources/pfam_database/table_pfam_description"

join -t $'\t' -1 2 -2 1 \
  <(sort -k2,2 "$FAMILIES") \
  <(sort -k1,1 "$PFAM_RESULTS") \
  | awk '{sub(/\..*/, "", $7); print $2"\t"$1"\t"$7}' \
  | sort -u \
  > "$DIR/fam_rep_pfam.tsv"

echo "Total Pfam hits: $(wc -l < "$DIR/fam_rep_pfam.tsv")"
echo "Families with a Pfam hit: $(cut -f1 "$DIR/fam_rep_pfam.tsv" | uniq | wc -l)"

join -t $'\t' -1 3 -2 1 \
  <(sort -k3,3 "$DIR/fam_rep_pfam.tsv") \
  "$DESCRIPTION" \
  | awk '{print $2"\t"$3"\t"$1"\t"$4}' \
  | sort -k1,1 \
  > "$DIR/fam_rep_pfam_description.tsv"

rm "$DIR/fam_rep_pfam.tsv"

echo "Wrote $DIR/fam_rep_pfam_description.tsv"
