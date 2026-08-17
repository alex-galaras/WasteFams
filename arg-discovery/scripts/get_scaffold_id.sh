#!/usr/bin/env bash
# Derive the scaffold-level contig id from each ORF's Prodigal header
# (format "<contig>_<gene_index> # start # end # strand # ...") and add it
# as a new leading column, so ARG hits can be joined to scaffold-level
# taxonomy/metadata downstream.
#
# Input:  $PROJECT_DIR/antimicrobial_resistance/rgi_results/analysisII/rgi_filtered.tsv
# Output: $PROJECT_DIR/antimicrobial_resistance/rgi_results/analysisII/rgi_processed.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

DIR="$PROJECT_DIR/antimicrobial_resistance/rgi_results/analysisII"

awk 'BEGIN{FS=OFS="\t"}
NR==1{
    printf "ORF_ID\tORF_ID_full"
    for(i=2; i<=NF; i++) printf "\t%s", $i
    printf "\n"; next
}
{
    split($1, parts, " # ")
    contig = parts[1]
    sub(/_[0-9]+$/, "", contig)
    printf "%s\t%s", contig, $1
    for(i=2; i<=NF; i++) printf "\t%s", $i
    printf "\n"
}' "$DIR/rgi_filtered.tsv" > "$DIR/rgi_processed.tsv"

echo "Wrote $DIR/rgi_processed.tsv"
