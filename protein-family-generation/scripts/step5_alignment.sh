#!/usr/bin/env bash
# Step 5: MAFFT alignment.
#
# 1. Split families into chunks of 1000 for parallel processing.
# 2. Align each family with MAFFT via mafft_parallel_controlled.py, which
#    extracts each cluster's sequences into a FASTA, aligns it with MAFFT,
#    and merges the aligned sequences back into the TSV rows. Chunks are
#    processed in parallel (6 files at a time, 5 CPUs each by default).
#    Sequences with the selenocysteine (U) amino acid are dropped by MAFFT
#    and need to be rerun with --anysymbol.
# 3. Reorder each family's rows so the representative sequence comes first
#    (needed for HHfilter's -M first in Step 6).
#
# Input:  $PROJECT_DIR/step3_protein_families/families_sequences.tsv
# Output: $PROJECT_DIR/step4_maft/mafft_aligned_final.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TSV="$PROJECT_DIR/step3_protein_families/families_sequences.tsv"
DIR="$PROJECT_DIR/step4_maft"
mkdir -p "$DIR"

# --- 1. Chunk families ---
cut -f1 "$TSV" | sort -u > "$DIR/family_ids.txt"
split -l 1000 -d --additional-suffix=.txt "$DIR/family_ids.txt" "$DIR/chunk_"

for chunk in "$DIR"/chunk_*.txt
do
  chunk_number=$(basename "$chunk" .txt)
  join -t $'\t' "$chunk" "$TSV" > "$DIR/${chunk_number}_subset.tsv"
done
ls "$DIR"/*_subset.tsv > "$DIR/chunks_list.txt"
rm "$DIR"/chunk_*.txt

# --- 2. Align each chunk with MAFFT ---
python3 "$SCRIPT_DIR/mafft_parallel_controlled.py" "$DIR/chunks_list.txt" \
  > "$DIR/mafft_aligned_output.tsv" 2> "$DIR/mafft_aligned_error.log"

# Remove rows with no cluster id (unsuccessful MAFFT)
awk -F'\t' 'NR==1 {print; next} $1 !~ /^ *$/ {print}' "$DIR/mafft_aligned_output.tsv" \
  | sort -k1,1 > "$DIR/mafft_aligned_processed.tsv"

# --- 3. Reorder: representative sequence first ---
Rscript "$SCRIPT_DIR/reorder_representative.R" \
  "$PROJECT_DIR/step3_protein_families/families_100.tsv" \
  "$DIR/mafft_aligned_processed.tsv" \
  "$DIR/mafft_aligned_final.tsv" \
  Family,SeqID,Seq,Alignment

echo "Wrote $DIR/mafft_aligned_final.tsv"
