#!/usr/bin/env bash
# Search every query structure against one foldseek reference database, then
# classify hits by which alignment test they satisfy (see pipeline.md for
# the rationale), and report how many HQ/MQ/LQ models (by pTM) got a hit.
#
# Usage: run_foldseek_search.sh <db_path> <label>
#   db_path: path to a pre-built foldseek database (CATH50, PDB, AlphaFold/UniProt...)
#   label:   short name for this database, used to namespace outputs (e.g. CATH50, PDB, alphafold)
#
# Input:  $PROJECT_DIR/structures/queries/*.cif
#         $PROJECT_DIR/structures/structures_results/{HQ,MQ,LQ}.tsv
# Output: $PROJECT_DIR/structures/<label>_results        (foldseek alignment table)
#         $PROJECT_DIR/structures/<label>_total_hits      (deduplicated hit id list)
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

DB_PATH="${1:?Usage: run_foldseek_search.sh <db_path> <label>}"
LABEL="${2:?Usage: run_foldseek_search.sh <db_path> <label>}"

QUERIES="$PROJECT_DIR/structures/queries"
RESULTS="$PROJECT_DIR/structures/${LABEL}_results"
TMP="$PROJECT_DIR/structures/tmp_${LABEL}"
STATS_DIR="$PROJECT_DIR/structures/structures_results"

foldseek easy-search \
  "$QUERIES" \
  "$DB_PATH" \
  "$RESULTS" \
  "$TMP" \
  --threads 16 \
  --format-output "query,target,fident,alnlen,mismatch,gapopen,qstart,qend,tstart,tend,evalue,bits,qlen,tlen,lddt,qtmscore,ttmscore,alntmscore,rmsd" \
  --format-mode 4

# hits_alntm: full-domain match (comparable sizes) -- alntmscore >= 0.5 (col 18)
awk '$18>=5.0E-01 {print$1}' "$RESULTS" | sort -u | grep -v "query" > "$PROJECT_DIR/structures/hits_alntm"

# hits_qscore: query smaller than target, query matches part of target -- qtmscore >= 0.5 (col 16)
awk '$13<$14 && $16>=5.0E-01 {print$1}' "$RESULTS" | sort -u | grep -v "query" > "$PROJECT_DIR/structures/hits_qscore"

# hits_tscore: query larger than target, target matches part of query -- ttmscore >= 0.5 (col 17)
awk '$13>$14 && $17>=5.0E-01 {print$1}' "$RESULTS" | sort -u | grep -v "query" > "$PROJECT_DIR/structures/hits_tscore"

cat "$PROJECT_DIR/structures/hits_alntm" "$PROJECT_DIR/structures/hits_qscore" "$PROJECT_DIR/structures/hits_tscore" \
  | sort -u > "$PROJECT_DIR/structures/${LABEL}_total_hits"
rm "$PROJECT_DIR/structures/hits_alntm" "$PROJECT_DIR/structures/hits_qscore" "$PROJECT_DIR/structures/hits_tscore"

TOTAL_HITS="$PROJECT_DIR/structures/${LABEL}_total_hits"
echo "$LABEL: HQ hits = $(join -1 1 -2 1 "$TOTAL_HITS" <(sort -k1,1 "$STATS_DIR/HQ.tsv") | wc -l)"
echo "$LABEL: MQ hits = $(join -1 1 -2 1 "$TOTAL_HITS" <(sort -k1,1 "$STATS_DIR/MQ.tsv") | wc -l)"
echo "$LABEL: LQ hits = $(join -1 1 -2 1 "$TOTAL_HITS" <(sort -k1,1 "$STATS_DIR/LQ.tsv") | wc -l)"
