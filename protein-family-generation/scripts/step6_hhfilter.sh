#!/usr/bin/env bash
# Step 6: HHfilter and trimming.
#
# 1. Split aligned families into chunks of 1000 for parallel processing.
# 2. Filter each alignment with hhfilter_parallel_30cores.py, which runs
#    `hhfilter -M first -id 95 -cov 70` per cluster and appends the filtered
#    alignment back onto the TSV rows (up to 40 clusters in parallel).
# 3. Re-derive families with >= 100 surviving members, and restore any
#    members HHfilter dropped from families that still qualify.
# 4. Trim alignment columns to the representative sequence's non-gap
#    positions with alignment_trimmer_15.py (30 chunk files in parallel).
#
# Input:  $PROJECT_DIR/step4_maft/mafft_aligned_final.tsv
# Output: $PROJECT_DIR/step5_hhfilter/hhfilter_members.tsv       (final family catalog)
#         $PROJECT_DIR/step5_hhfilter/trimming_output.tsv        (trimmed alignments)
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="$PROJECT_DIR/step5_hhfilter"
mkdir -p "$DIR"

# --- 1. Chunk aligned families ---
TSV="$PROJECT_DIR/step4_maft/mafft_aligned_final.tsv"
cut -f1 "$TSV" | sort -u > "$DIR/family_ids.txt"
split -l 1000 -d --additional-suffix=.txt "$DIR/family_ids.txt" "$DIR/chunk_"

for chunk in "$DIR"/chunk_*.txt
do
  chunk_number=$(basename "$chunk" .txt)
  join -t $'\t' "$chunk" "$TSV" > "$DIR/${chunk_number}_subset.tsv"
done
ls "$DIR"/chunk_*_subset.tsv > "$DIR/chunks_hhfilter.txt"
rm "$DIR"/chunk_*.txt

# --- 2. Run hhfilter (95% identity, 70% coverage, -M first) ---
python3 "$SCRIPT_DIR/hhfilter_parallel_30cores.py" "$DIR/chunks_hhfilter.txt" \
  > "$DIR/hhfilter_output.tsv" 2> "$DIR/hhfilter_error.log"

# --- 3. Re-derive families with >= 100 members after HHfilter ---
cut -f1 "$DIR/hhfilter_output.tsv" | uniq -c | awk '{print $2"\t"$1}' \
  | awk -F'\t' '$2 >= 100' | sort -k1,1 > "$DIR/families_greater_100.tsv"

sort -k1,1 "$DIR/hhfilter_output.tsv" > "$DIR/hhfilter_sorted.tsv"
join -t $'\t' -1 1 -2 1 "$DIR/hhfilter_sorted.tsv" "$DIR/families_greater_100.tsv" \
  | awk '{print $1"\t"$2"\t"$3"\t"$4"\t"$5}' | sort -k1,1 > "$DIR/input_domains.tsv"
rm "$DIR/hhfilter_sorted.tsv"

# Reorder: representative sequence first (needed before trimming)
Rscript "$SCRIPT_DIR/reorder_representative.R" \
  "$PROJECT_DIR/step3_protein_families/families_100.tsv" \
  "$DIR/input_domains.tsv" \
  "$DIR/input_domains_repfirst.tsv" \
  Family,SeqID,Seq,Alignment,HHmodel

# Restore members that were present before HHfilter but dropped by it,
# for families that still qualify with >= 100 members
join -t $'\t' -1 1 -2 1 "$PROJECT_DIR/step4_maft/mafft_aligned_processed.tsv" "$DIR/families_greater_100.tsv" \
  | sort -k1,1 > "$DIR/hhfilter_members.tsv"

# --- 4. Trim alignments to the representative's non-gap columns ---
cut -f1 "$DIR/input_domains_repfirst.tsv" | sort -u > "$DIR/family_ids.txt"
split -l 200 -d --additional-suffix=.txt "$DIR/family_ids.txt" "$DIR/chunk_"

for chunk in "$DIR"/chunk_*.txt
do
  chunk_number=$(basename "$chunk" .txt)
  join -t $'\t' "$chunk" "$DIR/input_domains_repfirst.tsv" > "$DIR/${chunk_number}_subset.tsv"
done
ls "$DIR"/chunk_*_subset.tsv > "$DIR/chunks_trimming.txt"
rm "$DIR"/chunk_*.txt

python3 "$SCRIPT_DIR/alignment_trimmer_15.py" "$DIR/chunks_trimming.txt" \
  > "$DIR/trimming_output.tsv" 2> "$DIR/trimming.log"

echo "Wrote $DIR/hhfilter_members.tsv (final family catalog) and $DIR/trimming_output.tsv"
