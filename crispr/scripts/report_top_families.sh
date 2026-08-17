#!/usr/bin/env bash
# Report which protein families and which Cas operons appear most often in
# the CRISPR/Cas-family intersection.
#
# Input: $PROJECT_DIR/crispr_elements/CAS_WWF_intersect.tab
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

CAS_WWF="$PROJECT_DIR/crispr_elements/CAS_WWF_intersect.tab"

echo "Top WWF families found in Cas operons:"
cut -f9 "$CAS_WWF" | sort | uniq -c | awk '{print $2"\t"$1}' | sort -k2,2 -nr | head

echo
echo "Cas operons with the most distinct WWF families:"
cut -f4 "$CAS_WWF" | sort | uniq -c | awk '{print $2"\t"$1}' | sort -k2,2 -nr | head
