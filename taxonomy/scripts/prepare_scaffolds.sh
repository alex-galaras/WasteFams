#!/usr/bin/env bash
# Convert all wastewater scaffolds to FASTA and split into ~60 Mbp chunks for
# parallel taxonomic classification. No minimum-length filter is applied —
# short scaffolds are still worth classifying taxonomically.
#
# Input:  $PROJECT_DIR/input_files/wastewater_scaffolds.tsv
# Output: $PROJECT_DIR/taxonomy/scaffold_chunks/scaffold_chunk_NNN.fasta
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

TSV="$PROJECT_DIR/input_files/wastewater_scaffolds.tsv"
OUTDIR="$PROJECT_DIR/taxonomy/scaffold_chunks"
PREFIX="scaffold_chunk"
TARGET_BP=60000000   # 60 Mbp per chunk

mkdir -p "$OUTDIR"

awk -F '\t' '{print ">"$1"\n"$2}' "$TSV" | \
awk -v outdir="$OUTDIR" -v prefix="$PREFIX" -v target="$TARGET_BP" '
BEGIN {
  file = 1
  bp = 0
  out = sprintf("%s/%s_%03d.fasta", outdir, prefix, file)
}
# Header line
/^>/ {
  if (bp >= target) {
    file++
    bp = 0
    out = sprintf("%s/%s_%03d.fasta", outdir, prefix, file)
  }
  print > out
  next
}
# Sequence line
{
  bp += length($0)
  print > out
}
'

echo "Wrote chunks to $OUTDIR"
