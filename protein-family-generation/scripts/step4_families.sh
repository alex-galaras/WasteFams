#!/usr/bin/env bash
# Step 4: Protein family generation.
#
# 1. Cluster the combined metagenome + isolate protein set into families
#    with MMseqs2 linclust at 30% identity / 80% coverage.
# 2. Keep families with >= 100 members and assign them WWF00001, WWF00002...
#    names, sorted by representative sequence id.
# 3. Build the per-member TSV (Family, MemberID, Sequence) used for alignment.
#
# Input:  $PROJECT_DIR/step2_deduplication_summary/total_sequences.fasta / .tsv
# Output: $PROJECT_DIR/step3_protein_families/families_100.tsv
#         $PROJECT_DIR/step3_protein_families/families_sequences.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

DIR="$PROJECT_DIR/step3_protein_families"
SUMMARY_DIR="$PROJECT_DIR/step2_deduplication_summary"
mkdir -p "$DIR"
cd "$DIR"

# --- 1. Cluster into families (30% identity, 80% coverage) ---
mmseqs createdb "$SUMMARY_DIR/total_sequences.fasta" DB
mmseqs linclust DB families tmp -c 0.8 --min-seq-id 0.3 --threads 12
mmseqs createtsv DB DB families families.tsv

echo "Unique clusters/families: $(cut -f1 families.tsv | sort -u | wc -l)"

# --- 2. Keep families with >= 100 members, assign WWF ids ---
cut -f1 families.tsv | sort | uniq -c | awk '{print $2 "\t" $1}' > family_counts.tsv

awk -F'\t' '$2 >= 100 {print $1 "\t" $2}' family_counts.tsv \
  | sort -k1,1 \
  | awk -v OFS='\t' '{printf "WWF%05d\t%s\n", NR, $0}' \
  > families_100.tsv

# --- 3. Build the per-member TSV: Family  MemberID  Sequence ---
sort -k1,1 families.tsv > families.sorted.tsv

# Add family name to MMseqs clusters, sort by member id
join -t $'\t' -1 1 -2 2 families.sorted.tsv families_100.tsv \
  | awk -F'\t' '{print $3"\t"$2}' \
  | sort -k2,2 \
  > families_allids.tsv

# Merge with the initial TSV -> Family  MemberID  Sequence
join -t $'\t' -1 2 -2 1 families_allids.tsv "$SUMMARY_DIR/total_sequences.tsv" \
  | awk -F'\t' '{print $2"\t"$1"\t"$3}' \
  | sort -k1,1 \
  > families_sequences.tsv

rm families.sorted.tsv families_allids.tsv

echo "Wrote $DIR/families_100.tsv and $DIR/families_sequences.tsv"
