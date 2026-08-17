#!/usr/bin/env bash
# Step 2: Metagenome deduplication.
#
# 1. Count proteins per taxon in the raw metagenome protein FASTA.
# 2. Link each taxon to its GOLD sequencing ID via wastewater_merged.tsv,
#    then keep one dataset per unique GOLD ID (the one with the most proteins).
# 3. Filter the FASTA down to those unique GOLD-linked taxa.
# 4. Collapse 100%-identical sequences with MMseqs2 linclust.
#
# Input:  $PROJECT_DIR/metagenomes/stepI_fasta_filtering/Wastewater_Metag.fasta
#         $PROJECT_DIR/metadata/wastewater_merged.tsv
# Output: $PROJECT_DIR/metagenomes/stepI_fasta_filtering/final_metag_filtered.fa
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

DIR="$PROJECT_DIR/metagenomes/stepI_fasta_filtering"
cd "$DIR"

# --- 1. Count proteins per taxon ---
# Extract headers, strip ">", keep taxon id, count occurrences per taxon
grep ">" Wastewater_Metag.fasta | sed 's/>//g' | cut -d "|" -f1 | sort | uniq -c \
  | awk '{print $2 "\t" $1}' > Dataset_ProteinC.tsv

# --- 2. Link each taxon to its GOLD sequencing ID, keep one dataset per ID ---
sort -t $'\t' -k1,1 Dataset_ProteinC.tsv -o Dataset_ProteinC_sorted.tsv

# Column 23 of wastewater_merged.tsv is the GOLD sequencing ID (join key)
tail -n +2 "$PROJECT_DIR/metadata/wastewater_merged.tsv" \
  | sort -t $'\t' -k1,1 -o "$PROJECT_DIR/metadata/wastewater_merged_sorted.tsv"

join -t $'\t' -1 1 -2 1 -o 1.1,1.2,2.23 \
  Dataset_ProteinC_sorted.tsv \
  "$PROJECT_DIR/metadata/wastewater_merged_sorted.tsv" \
  > dataset_gold.tsv

# Keep one dataset per unique GOLD ID, preferring the one with the most proteins
sort -k3,3 -k2,2 dataset_gold.tsv | awk '!seen[$3]++' > dataset_unique_gold.tsv

# --- 3. Filter the FASTA to unique GOLD-linked taxa ---
# Keep FASTA entries whose taxon id (first field before "|") is in the GOLD-linked TSV
awk 'NR==FNR {keep[$1]; next} /^>/ {split($1,a,"|"); taxon=substr(a[1],2); keepseq = (taxon in keep)} keepseq' \
  dataset_unique_gold.tsv Wastewater_Metag.fasta > Wastewater_Metag_uniqgold.fasta

# --- 4. Collapse 100%-identical sequences with MMseqs2 linclust ---
mmseqs createdb Wastewater_Metag_uniqgold.fasta DB
mmseqs linclust DB clusters tmp -c 1 --min-seq-id 1 --threads 12
mmseqs createtsv DB DB clusters clusters.tsv

# --- 5. Keep only the deduplicated sequences ---
# Rebuild id|taxon|scaffold -> sequence lookup, sorted for joining
awk '{print$1"|"$2"|"$3"\t"$10}' Wastewater_Metag.tsv | sort -k1,1 > sorted_metag_seq.tsv
cut -f1 clusters.tsv | sort -u > sorted_deduplicated_mmseqs.txt

join -t $'\t' -1 1 -2 1 sorted_metag_seq.tsv sorted_deduplicated_mmseqs.txt \
  | awk '{print">"$1"\n"$2}' > final_metag_filtered.fa

echo "Wrote $DIR/final_metag_filtered.fa"
echo "Unique clusters/sequences: $(cut -f1 clusters.tsv | uniq | wc -l)"
