#!/usr/bin/env bash
# Convert CCTyper's CRISPR arrays, Cas operons, and the protein-family gene
# coordinates to BED, then intersect to find which protein families overlap
# a CRISPR array or a predicted Cas operon.
#
# Input:  $PROJECT_DIR/members_link_prodigal/WWF_IMG_prodigal.tsv
#         $PROJECT_DIR/crispr_elements/crisprs_all_results.tab
#         $PROJECT_DIR/crispr_elements/cas9_operons_results.tab
# Output: $PROJECT_DIR/crispr_elements/CRISPR_WWF_intersect.tab
#         $PROJECT_DIR/crispr_elements/CAS_WWF_intersect.tab
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

WWF_coord="$PROJECT_DIR/members_link_prodigal/WWF_IMG_prodigal.tsv"
CRISPR_arrays="$PROJECT_DIR/crispr_elements/crisprs_all_results.tab"
CAS_OPERONS="$PROJECT_DIR/crispr_elements/cas9_operons_results.tab"
OUT="$PROJECT_DIR/crispr_elements"

# Convert WWF gene coordinates to BED (contig=col4, start=col5, end=col6,
# name=col1|col2, strand=col7). Prodigal coordinates are 1-based; subtract 1
# from start for 0-based BED.
awk 'BEGIN{OFS="\t"} {print $4, $5-1, $6, $1, $2, $7}' "$WWF_coord" \
  | sort -k1,1 -k2,2n > "$OUT/WWF.bed"

# Convert CRISPR arrays to BED (skip header; contig=col1, start=col3, end=col4,
# name=col2, subtype=col14). CCTyper coordinates are 1-based.
tail -n +2 "$CRISPR_arrays" \
  | awk 'BEGIN{OFS="\t"} {print $1, $3-1, $4, $2, $13, $14}' \
  | sort -k1,1 -k2,2n > "$OUT/CRISPR_arrays.bed"

# Convert Cas operons to BED (skip header; contig=col1, start=col3, end=col4,
# name=col2, prediction=col5)
tail -n +2 "$CAS_OPERONS" \
  | awk 'BEGIN{OFS="\t"} {print $1, $3-1, $4, $2, $5}' \
  | sort -k1,1 -k2,2n > "$OUT/CAS_operons.bed"

# Intersect CRISPR arrays with WWF protein families (-wa -wb: report all
# columns from both sides). Output columns: contig, crispr_start, crispr_end,
# crispr_id, trusted, subtype | contig, wwf_start, wwf_end, wwf_family, gene_id, strand
bedtools intersect \
  -a "$OUT/CRISPR_arrays.bed" \
  -b "$OUT/WWF.bed" \
  -wa -wb \
  > "$OUT/CRISPR_WWF_intersect.tab"

echo "CRISPR-WWF intersections: $(wc -l < "$OUT/CRISPR_WWF_intersect.tab")"

# Intersect Cas operons with WWF protein families. Output columns: contig,
# operon_start, operon_end, operon_id, prediction | contig, wwf_start, wwf_end,
# wwf_family, gene_id, strand
bedtools intersect \
  -a "$OUT/CAS_operons.bed" \
  -b "$OUT/WWF.bed" \
  -wa -wb \
  > "$OUT/CAS_WWF_intersect.tab"

echo "Cas operon-WWF intersections: $(wc -l < "$OUT/CAS_WWF_intersect.tab")"
