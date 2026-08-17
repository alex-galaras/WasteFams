#!/usr/bin/env bash
# Build a searchable protein database from the Mobile Genetic Element
# Database (MGEdb): https://github.com/KatariinaParnanen/MobileGeneticElementDatabase
#
# Input:  $PROJECT_DIR/resources/MobileGeneticElementDatabase/MGEs_FINAL_99perc_trim.fasta
# Output: $PROJECT_DIR/resources/MobileGeneticElementDatabase/MGEdb.dmnd
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

MGE_DIR="$PROJECT_DIR/resources/MobileGeneticElementDatabase"

# Call genes on the MGE nucleotide sequences
prodigal -i "$MGE_DIR/MGEs_FINAL_99perc_trim.fasta" \
  -a "$MGE_DIR/mge.proteins.faa" \
  -d "$MGE_DIR/mge.genes.faa" \
  -p meta

diamond makedb \
  --in "$MGE_DIR/mge.proteins.faa" \
  -d "$MGE_DIR/MGEdb"

echo "Wrote $MGE_DIR/MGEdb.dmnd"
