#!/usr/bin/env bash
# Assign each MGE hit its functional class (from the MGEdb taxonomy table),
# then link classified hits to the protein family each gene belongs to.
#
# Input:  $PROJECT_DIR/mges/all_vs_MGE.besthit.tsv
#         $PROJECT_DIR/resources/MobileGeneticElementDatabase/MGE_tax_table_trim.txt
#         $PROJECT_DIR/members_link_prodigal/WWF_IMG_prodigal.tsv
# Output: $PROJECT_DIR/mges/all_vs_MGE.with_class.ALL.tsv
#         $PROJECT_DIR/mges/mge_families.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

DIR="$PROJECT_DIR/mges"
MGE="$DIR/all_vs_MGE.besthit.tsv"
MGE_CLASSES="$PROJECT_DIR/resources/MobileGeneticElementDatabase/MGE_tax_table_trim.txt"
FAM_MEMBERS_COORD="$PROJECT_DIR/members_link_prodigal/WWF_IMG_prodigal.tsv"

# Strip the "_<gene_index>" suffix from the MGEdb hit id so it matches the
# taxonomy table's key
awk -F'\t' '{ sub(/_[0-9]+$/, "", $2); print }' OFS='\t' "$MGE" > "$DIR/all_vs_MGE.besthit.no_suffix.tsv"

# Merge to get MGE functional classes; unmatched hits become "unclassified"
join -t $'\t' -a1 -e "unclassified" -1 2 -2 1 \
  -o 1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,2.2 \
  <(sort -k2,2 "$DIR/all_vs_MGE.besthit.no_suffix.tsv") \
  <(sort -k1,1 "$MGE_CLASSES") \
  > "$DIR/all_vs_MGE.with_class.ALL.tsv"

# Link each classified hit to its protein family
cut -f1,3 "$FAM_MEMBERS_COORD" > "$DIR/coord.tmp.tsv"

join -t $'\t' -1 1 -2 2 \
  <(sort -k1,1 "$DIR/all_vs_MGE.with_class.ALL.tsv") \
  <(sort -k2,2 "$DIR/coord.tmp.tsv") \
  | sort -k9,9 \
  > "$DIR/mge_families.tsv"

rm "$DIR/coord.tmp.tsv"

echo "Wrote $DIR/all_vs_MGE.with_class.ALL.tsv and $DIR/mge_families.tsv"
