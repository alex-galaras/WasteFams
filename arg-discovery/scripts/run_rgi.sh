#!/usr/bin/env bash
# Run RGI (Resistance Gene Identifier) against CARD on all Prodigal-called
# proteins, chunk by chunk.
#
# Input:  $PROJECT_DIR/antimicrobial_resistance/fasta_chunks/*.fasta
# Output: $PROJECT_DIR/antimicrobial_resistance/rgi_results/<chunk>_rgi.txt (per chunk)
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

INPUT_DIR="$PROJECT_DIR/antimicrobial_resistance/fasta_chunks"
OUT_DIR="$PROJECT_DIR/antimicrobial_resistance/rgi_results"
mkdir -p "$OUT_DIR"

# RGI chokes on trailing "*" stop-codon markers in protein FASTAs
sed -i 's/\*$//' "$INPUT_DIR"/*.fasta

for faa in "$INPUT_DIR"/*.fasta; do
  base=$(basename "$faa" .fasta)
  echo "Running RGI on: $base"

  rgi main \
    --input_sequence "$faa" \
    --output_file "$OUT_DIR/${base}_rgi" \
    --input_type protein \
    --alignment_tool diamond \
    --num_threads 8 \
    --clean \
    --local \
    -g PRODIGAL
done

# Merge all per-chunk RGI outputs into one summary table (single header)
first_chunk=$(ls "$OUT_DIR"/*_rgi.txt | head -1)
head -1 "$first_chunk" > "$OUT_DIR/rgi_summary.tsv"
for f in "$OUT_DIR"/*_rgi.txt; do
  tail -n +2 "$f" >> "$OUT_DIR/rgi_summary.tsv"
done

echo "Wrote $OUT_DIR/rgi_summary.tsv"
