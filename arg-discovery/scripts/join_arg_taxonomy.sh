#!/usr/bin/env bash
# Join each ARG hit to the taxonomic lineage of its source scaffold.
#
# Input:  $PROJECT_DIR/taxonomy/filtered_WW_scaffolds_taxon_lineage
#         $PROJECT_DIR/antimicrobial_resistance/rgi_results/analysisII/rgi_processed.tsv
# Output: $PROJECT_DIR/antimicrobial_resistance/rgi_results/analysisII/rgi_taxa.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

TAXA="$PROJECT_DIR/taxonomy/filtered_WW_scaffolds_taxon_lineage"
DIR="$PROJECT_DIR/antimicrobial_resistance/rgi_results/analysisII"
ARGS="$DIR/rgi_processed.tsv"
OUT="$DIR/rgi_taxa.tsv"

# Extract scaffold + taxonomic lineage columns
awk -F '\t' '{print $1"\t"$5}' "$TAXA" > "$DIR/scaffold_taxa.tsv"

# Write header: ARG header with "Taxa" inserted as second column
head -1 "$ARGS" | awk -F '\t' '{print $1"\tTaxa\t" substr($0, index($0,$2))}' > "$OUT"

# Join data (skipping headers) and append
join -t $'\t' -1 1 -2 1 \
  <(tail -n +2 "$DIR/scaffold_taxa.tsv" | sort -t $'\t' -k1,1) \
  <(tail -n +2 "$ARGS" | sort -t $'\t' -k1,1) >> "$OUT"

echo "Wrote $OUT"
