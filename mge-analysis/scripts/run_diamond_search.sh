#!/usr/bin/env bash
# Search the wastewater protein set against the MGE database, then keep only
# hits with identity >= 30% and the best hit per query protein.
#
# Input:  $PROJECT_DIR/antimicrobial_resistance/fasta_chunks/*.fasta
#         $PROJECT_DIR/resources/MobileGeneticElementDatabase/MGEdb.dmnd
# Output: $PROJECT_DIR/mges/all_vs_MGE.besthit.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

MGE_DIR="$PROJECT_DIR/resources/MobileGeneticElementDatabase"
INPUT_DIR="$PROJECT_DIR/antimicrobial_resistance/fasta_chunks"
OUT="$PROJECT_DIR/mges"
mkdir -p "$OUT"

for faa in "$INPUT_DIR"/*.fasta; do
  base=$(basename "$faa" .fasta)
  echo "Processing $base"

  diamond blastp \
    --query "$faa" \
    --db "$MGE_DIR/MGEdb.dmnd" \
    --out "$OUT/${base}.tsv" \
    --outfmt 6 qseqid sseqid pident length qlen slen evalue bitscore \
    --evalue 1e-5 \
    --max-target-seqs 10 \
    --threads 24 \
    > "$OUT/${base}.diamond.log" 2>&1
done

cat "$OUT"/*.tsv > "$OUT/all_vs_MGE.raw.tsv"

# Identity >= 30% & only the best hit per query (highest bitscore)
awk -F '\t' '$3 >= 30' "$OUT/all_vs_MGE.raw.tsv" \
  | sort -k1,1 -k8,8nr \
  | awk '!seen[$1]++' > "$OUT/all_vs_MGE.besthit.tsv"

echo "Wrote $OUT/all_vs_MGE.besthit.tsv"
