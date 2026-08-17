#!/usr/bin/env bash
# Step 3: Isolate filtering.
#
# 1. Keep isolate proteins >= 35 aa.
# 2. TANTAN low-complexity filtering: sequences with < 10 consecutive Xs are
#    kept unchanged; sequences with >= 10 consecutive Xs have the Xs stripped
#    and are kept only if the remaining sequence is still >= 35 aa.
# 3. Merge the surviving isolate proteins with the deduplicated metagenome
#    proteins from Step 2 into the final combined protein set.
#
# Input:  $PROJECT_DIR/isolates/Wastewater_Iso.fasta
#         $PROJECT_DIR/metagenomes/stepI_fasta_filtering/final_metag_filtered.fa
# Output: $PROJECT_DIR/step2_deduplication_summary/total_sequences.fasta / .tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

ISO_DIR="$PROJECT_DIR/isolates"
FILT_DIR="$ISO_DIR/step1_filtering"
TANTAN_DIR="$FILT_DIR/tantan_filtering"
mkdir -p "$FILT_DIR" "$TANTAN_DIR"

# --- 3a. Filter isolates to >= 35 aa ---
FASTA="$ISO_DIR/Wastewater_Iso.fasta"
TSV="$ISO_DIR/Wastewater_Iso.tsv"
TSV_aa="$ISO_DIR/Wastewater_Iso_aa.tsv"
TSV_35aa="$FILT_DIR/Wastewater_Iso_35aa.tsv"
ISOLATES_FASTA="$FILT_DIR/Wastewater_Iso_35aa.fasta"

# FASTA -> TSV (id, sequence)
awk '/^>/ {
    if (seq) print id, seq;
    id=substr($0,2);
    seq="";
    next
}
{ seq = seq $0 }
END { if (seq) print id, seq }' OFS='\t' "$FASTA" | sort -k1,1 > "$TSV"

awk -F'\t' 'BEGIN {OFS="\t"} {print $1, $2, length($2)}' "$TSV" > "$TSV_aa"
awk -F'\t' 'BEGIN {OFS="\t"} $3 >= 35 {print $1, $2}' "$TSV_aa" > "$TSV_35aa"
awk '{print">"$1"\n"$2}' "$TSV_35aa" > "$ISOLATES_FASTA"

# --- 3b. TANTAN low-complexity filtering ---
OUTPUT="$TANTAN_DIR/Wastewater_Iso_tantan.fasta"
OUTPUT_TSV="$TANTAN_DIR/Wastewater_Iso_tantan.tsv"

tantan -p "$ISOLATES_FASTA" -x X > "$OUTPUT"

awk '/^>/ {
    if (seq) print id, seq;
    id=substr($0,2);
    seq="";
    next
}
{ seq = seq $0 }
END { if (seq) print id, seq }' OFS='\t' "$OUTPUT" | sort -k1,1 > "$OUTPUT_TSV"

# Dataset 1: sequences with < 10 consecutive Xs, kept unchanged
TSV_keep="$TANTAN_DIR/Wastewater_Iso_tantan_keep.tsv"
DATASET1="$TANTAN_DIR/DATASET1.tsv"
awk -F '\t' '$2 !~ /X{10,}/' "$OUTPUT_TSV" | sort -k1,1 > "$TSV_keep"
join -t $'\t' -1 1 -2 1 "$TSV_keep" "$TSV_35aa" > "$DATASET1"

# Dataset 2: sequences with >= 10 consecutive Xs, Xs stripped, re-checked for length
TSV_discarded="$TANTAN_DIR/Wastewater_Iso_tantan_discarded.tsv"
DATASET2="$TANTAN_DIR/DATASET2.tsv"
awk -F '\t' '$2 ~ /X{10,}/' "$OUTPUT_TSV" | awk -F '\t' '{gsub(/X+/, "", $2); print $1 "\t" $2}' | sort -k1,1 > "$TSV_discarded"
awk 'length($2) >= 35' "$TSV_discarded" > "$DATASET2"

# Merge both datasets
FINAL_TSV="$TANTAN_DIR/Wastewater_Iso_35aa_TANTAN.tsv"
FINAL_FASTA="$TANTAN_DIR/Wastewater_Iso_35aa_TANTAN.fasta"
cat "$DATASET1" "$DATASET2" | sort -k1,1 > "$FINAL_TSV"
awk -F'\t' '{print ">" $1 "\n" $2}' "$FINAL_TSV" > "$FINAL_FASTA"

# --- Merge metagenome and isolate protein sets ---
SUMMARY_DIR="$PROJECT_DIR/step2_deduplication_summary"
mkdir -p "$SUMMARY_DIR"

cat "$PROJECT_DIR/metagenomes/stepI_fasta_filtering/final_metag_filtered.fa" "$FINAL_FASTA" \
  > "$SUMMARY_DIR/total_sequences.fasta"

awk '/^>/ {
    if (seq) print id, seq;
    id=substr($0,2);
    seq="";
    next
}
{ seq = seq $0 }
END { if (seq) print id, seq }' OFS='\t' "$SUMMARY_DIR/total_sequences.fasta" | sort -k1,1 \
  > "$SUMMARY_DIR/total_sequences.tsv"

echo "Wrote $SUMMARY_DIR/total_sequences.fasta"
