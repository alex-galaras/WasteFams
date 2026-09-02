#!/usr/bin/env bash
# List every AlphaFold3 input JSON and split the list into fixed-size chunks,
# one chunk per SLURM array task in Step 4.
#
# Input:  $PROJECT_DIR/structures/json_files/*.json
# Output: $PROJECT_DIR/structures/json_chunks/chunk_NNN (one JSON path per line, CHUNK_SIZE lines each)
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

JSON_DIR="$PROJECT_DIR/structures/json_files"
OUTDIR="$PROJECT_DIR/structures/json_chunks"
CHUNK_SIZE=2

mkdir -p "$OUTDIR"

ls "$JSON_DIR"/*.json > "$OUTDIR/all_jsons.list"
split -l "$CHUNK_SIZE" "$OUTDIR/all_jsons.list" "$OUTDIR/chunk_"

# Rename split's default chunk_aa/chunk_ab/... suffixes to zero-padded numbers
n=0
for f in "$OUTDIR"/chunk_??; do
  mv "$f" "$OUTDIR/$(printf "chunk_%03d" "$n")"
  n=$((n + 1))
done

echo "Wrote $((n)) chunks of $CHUNK_SIZE JSON file(s) each to $OUTDIR"
echo "Set --array=0-$((n - 1))%<concurrency> in Step 4's SLURM script to match."
