#!/usr/bin/env bash
# Taxonomic assignment of scaffold chunks with MMseqs2 taxonomy against
# UniRef90.
#
# Input:  $PROJECT_DIR/taxonomy/scaffold_chunks/*.fasta,
#         $PROJECT_DIR/resources/uniref90/uniref90DB
# Output: $PROJECT_DIR/taxonomy/mmseqs_taxonomy/<chunk>/taxonomyResult.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

UNIREF90_DB="$PROJECT_DIR/resources/uniref90/uniref90DB"
INPUT_DIR="$PROJECT_DIR/taxonomy/scaffold_chunks"
OUT="$PROJECT_DIR/taxonomy/mmseqs_taxonomy"
mkdir -p "$OUT"

for chunk in "$INPUT_DIR"/*.fasta; do
  base=$(basename "$chunk" .fasta)
  echo "Running MMseqs2 taxonomy on: $base"

  CHUNK_DIR="$OUT/$base"
  TMP="$CHUNK_DIR/tmp"
  mkdir -p "$TMP"

  mmseqs createdb "$chunk" "$CHUNK_DIR/queryDB"
  mmseqs taxonomy "$CHUNK_DIR/queryDB" "$UNIREF90_DB" "$CHUNK_DIR/taxonomyResult" "$TMP"
  mmseqs createtsv "$CHUNK_DIR/queryDB" "$CHUNK_DIR/taxonomyResult" "$CHUNK_DIR/taxonomyResult.tsv"

  rm -rf "$TMP"
done

echo "Wrote MMseqs2 taxonomy results to $OUT"
