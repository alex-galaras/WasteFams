#!/usr/bin/env bash
# Keep scaffolds longer than 5000 bp (the minimum antiSMASH needs to call a
# cluster) and split the result into ~60 Mbp chunks for parallel antiSMASH runs.
#
# Input:  $PROJECT_DIR/input_files/wastewater_scaffolds.tsv
# Output: $PROJECT_DIR/input_files/wastewater_scaffolds_greater5000.fasta,
#         $PROJECT_DIR/bgc_discovery/scaffold_chunks/scaffold_chunk_NNN.fasta
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

TSV="$PROJECT_DIR/input_files/wastewater_scaffolds.tsv"
FILTERED="$PROJECT_DIR/input_files/wastewater_scaffolds_greater5000.fasta"
OUTDIR="$PROJECT_DIR/bgc_discovery/scaffold_chunks"
PREFIX="scaffold_chunk"
TARGET_BP=60000000   # 60 Mbp per chunk

awk -F '\t' 'length($2) > 5000' "$TSV" \
  | awk -F '\t' '{print ">"$1"\n"$2}' \
  > "$FILTERED"

mkdir -p "$OUTDIR"

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
' "$FILTERED"

echo "Wrote $FILTERED and chunks to $OUTDIR"
