#!/usr/bin/env bash
# HMMER search of family-representative sequences against Pfam-A.
#
# Input:  $PROJECT_DIR/analysisII_pfam/input_pfam.tsv,
#         $PROJECT_DIR/resources/pfam_database/Pfam-A.hmm
# Output: $PROJECT_DIR/analysisII_pfam/pfam_results.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

DIR="$PROJECT_DIR/analysisII_pfam"
TSV="$DIR/input_pfam.tsv"
PFAM="$PROJECT_DIR/resources/pfam_database/Pfam-A.hmm"

awk '{print ">" $2 "\n" $3}' "$TSV" > "$DIR/pfam.fasta"

hmmsearch -T 25 \
  --domT 22 \
  --incT 7 \
  --incdomT 5 \
  --cpu 20 \
  --domtblout "$DIR/results.tblout" \
  -o "$DIR/results.hmmout" \
  "$PFAM" \
  "$DIR/pfam.fasta"

awk '!/^#/' "$DIR/results.tblout" | awk '{$1=$1}1' OFS='\t' > "$DIR/pfam_results.tsv"

echo "Wrote $DIR/pfam_results.tsv"
