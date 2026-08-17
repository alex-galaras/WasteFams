#!/usr/bin/env bash
# Restrict the BGC/protein-family co-occurrence edge list to RiPP BGCs only.
#
# bgc_class.tsv and edges.tsv come from a separate BGC/family co-occurrence
# network analysis that is not part of this pipeline (see pipeline.md).
#
# Input:  $PROJECT_DIR/bgc_discovery/cooccurrence_network/bgc_class.tsv,
#         $PROJECT_DIR/bgc_discovery/cooccurrence_network/edges.tsv
# Output: $PROJECT_DIR/bgc_discovery/ripp_upset/edges_ripp.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

NETWORK_DIR="$PROJECT_DIR/bgc_discovery/cooccurrence_network"
OUT_DIR="$PROJECT_DIR/bgc_discovery/ripp_upset"
mkdir -p "$OUT_DIR"

awk '$2=="RiPP"' "$NETWORK_DIR/bgc_class.tsv" | cut -f1 > "$OUT_DIR/ripp_ids.txt"

grep -F -f "$OUT_DIR/ripp_ids.txt" "$NETWORK_DIR/edges.tsv" > "$OUT_DIR/edges_ripp.tsv"

echo "Wrote $OUT_DIR/edges_ripp.tsv"
