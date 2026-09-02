#!/usr/bin/env bash
# Taxonomic classification of scaffold chunks with Kraken2 against a RefSeq
# database.
#
# Input:  $PROJECT_DIR/taxonomy/scaffold_chunks/*.fasta,
#         $PROJECT_DIR/resources/kraken2_refseq/
# Output: $PROJECT_DIR/taxonomy/kraken2/<chunk>.output.txt,
#         $PROJECT_DIR/taxonomy/kraken2/<chunk>.report.txt,
#         $PROJECT_DIR/taxonomy/kraken2/<chunk>.classified.fa,
#         $PROJECT_DIR/taxonomy/kraken2/<chunk>.unclassified.fa
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

DB="$PROJECT_DIR/resources/kraken2_refseq"
INPUT_DIR="$PROJECT_DIR/taxonomy/scaffold_chunks"
OUT="$PROJECT_DIR/taxonomy/kraken2"
mkdir -p "$OUT"

for chunk in "$INPUT_DIR"/*.fasta; do
  base=$(basename "$chunk" .fasta)
  echo "Running Kraken2 on: $base"

  kraken2 \
    --db "$DB" \
    --threads 16 \
    --output "$OUT/${base}.output.txt" \
    --report "$OUT/${base}.report.txt" \
    --use-names \
    --use-mpa-style \
    --classified-out "$OUT/${base}.classified.fa" \
    --unclassified-out "$OUT/${base}.unclassified.fa" \
    "$chunk"
done

echo "Wrote Kraken2 output to $OUT"
