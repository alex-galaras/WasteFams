#!/usr/bin/env bash
# Map Pfam sequence ids to gene names, then DIAMOND-search every gene
# neighborhood FASTA chunk against the Pfam sequence database, keeping only
# the best (first-listed) hit per query.
#
# Input:  $PROJECT_DIR/input_files/fasta_chunks/*.fasta,
#         $PROJECT_DIR/resources/pfam_database/pfamdb.dmnd,
#         $PROJECT_DIR/resources/pfam_database/pfamseq
# Output: $PROJECT_DIR/gene_neighborhood/pfam_id2gene.tsv,
#         $PROJECT_DIR/gene_neighborhood/<chunk>.besthit.tsv (per chunk)
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

PFAM_DB="$PROJECT_DIR/resources/pfam_database/pfamdb.dmnd"
PFAMSEQ="$PROJECT_DIR/resources/pfam_database/pfamseq"
INPUT_DIR="$PROJECT_DIR/input_files/fasta_chunks"
OUT="$PROJECT_DIR/gene_neighborhood"
mkdir -p "$OUT"

# Map Pfam sequence ids to gene names
awk '
/^>/ {
  id=substr($1,2)
  gene="NA"
  if (match($0, /GN=([^ ]+)/, g)) gene=g[1]
  print id "\t" gene
}
' "$PFAMSEQ" > "$OUT/pfam_id2gene.tsv"

for faa in "$INPUT_DIR"/*.fasta; do
  base=$(basename "$faa" .fasta)
  echo "Processing $base"

  diamond blastp \
    --query "$faa" \
    --db "$PFAM_DB" \
    --out "$OUT/${base}.tsv" \
    --outfmt 6 qseqid sseqid pident length qlen slen evalue bitscore \
    --evalue 1e-5 \
    --max-target-seqs 10 \
    --threads 24 \
    > "$OUT/${base}.diamond.log" 2>&1

  # Keep only the best (first) hit per query
  awk '!seen[$1]++' "$OUT/${base}.tsv" > "$OUT/${base}.besthit.tsv"
  rm "$OUT/${base}.tsv"
done

echo "Wrote $OUT/pfam_id2gene.tsv and per-chunk *.besthit.tsv"
