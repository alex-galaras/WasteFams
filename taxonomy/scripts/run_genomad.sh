#!/usr/bin/env bash
# Virus/plasmid identification on scaffold chunks with geNomad.
#
# Input:  $PROJECT_DIR/taxonomy/scaffold_chunks/*.fasta,
#         $PROJECT_DIR/resources/genomad_db/
# Output: $PROJECT_DIR/taxonomy/genomad/<chunk>/
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

DB="$PROJECT_DIR/resources/genomad_db"
INPUT_DIR="$PROJECT_DIR/taxonomy/scaffold_chunks"
OUT="$PROJECT_DIR/taxonomy/genomad"
mkdir -p "$OUT"

for chunk in "$INPUT_DIR"/*.fasta; do
  base=$(basename "$chunk" .fasta)
  echo "Running geNomad on: $base"

  genomad end-to-end "$chunk" "$OUT/$base" "$DB"
done

echo "Wrote geNomad output to $OUT"
