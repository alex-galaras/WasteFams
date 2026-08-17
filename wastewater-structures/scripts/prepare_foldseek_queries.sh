#!/usr/bin/env bash
# Collect every model's mmCIF into one query folder (as <family_id>.cif),
# ready for foldseek easy-search.
#
# Input:  $PROJECT_DIR/structures/metrics.tsv (column 1: family id, column 6: cif path)
# Output: $PROJECT_DIR/structures/queries/<family_id>.cif (symlinks)
#         $PROJECT_DIR/structures/structures_results/ALL_pairs.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

METRICS="$PROJECT_DIR/structures/metrics.tsv"
DIR="$PROJECT_DIR/structures/structures_results"
QUERIES="$PROJECT_DIR/structures/queries"
mkdir -p "$QUERIES" "$DIR"

# model_cif may be an absolute path or relative to $PROJECT_DIR
awk -F'\t' -v queries="$QUERIES" -v project_dir="$PROJECT_DIR" '
NR>1 {
  cif = ($6 ~ /^\//) ? $6 : project_dir "/" $6
  system("ln -sf \"" cif "\" \"" queries "/" $1 ".cif\"")
}' "$METRICS"

awk -F'\t' 'NR>1 {print $1"\t"$6}' "$METRICS" > "$DIR/ALL_pairs.tsv"

echo "Symlinked models into $QUERIES"
