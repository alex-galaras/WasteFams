#!/usr/bin/env bash
# CRISPR-Cas system typing with CCTyper, run directly on scaffold sequences
# (CCTyper calls genes itself via Prodigal in metagenome mode).
#
# Input:  $PROJECT_DIR/taxonomy/scaffold_chunks/*.fasta
# Output: $PROJECT_DIR/crispr_elements/cctyper_output/<chunk>/
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

DIR="$PROJECT_DIR/taxonomy/scaffold_chunks"
OUTPUT="$PROJECT_DIR/crispr_elements/cctyper_output"
mkdir -p "$OUTPUT"

for faa in "$DIR"/*.fasta
do
  base=$(basename "$faa" .fasta)
  cctyper -t 24 \
    --prodigal meta \
    "$faa" "$OUTPUT/${base}"
done
