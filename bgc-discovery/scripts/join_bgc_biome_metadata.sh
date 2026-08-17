#!/usr/bin/env bash
# Join each BGC to its source dataset's project type and ecosystem type, so
# BGC class/product distributions can be broken down by biome.
#
# Input:  $PROJECT_DIR/bgc_discovery/bgc_feature_summary.tsv,
#         $PROJECT_DIR/metadata/wastewater_merged.tsv
# Output: $PROJECT_DIR/bgc_discovery/bgc_biomes.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

BGC="$PROJECT_DIR/bgc_discovery/bgc_feature_summary.tsv"
METADATA="$PROJECT_DIR/metadata/wastewater_merged.tsv"
DIR="$PROJECT_DIR/bgc_discovery"

# Temporary table of dataset id -> project type / ecosystem type
awk -F'\t' '
BEGIN {
    OFS = "\t"
}

NR==1 {
    for (i = 1; i <= NF; i++) {
        idx[$i] = i
    }
    if (!("taxon_oid" in idx)) {
        print "ERROR: column \"taxon_oid\" not found" > "/dev/stderr"
        exit 1
    }
    if (!("GOLD Analysis Project Type" in idx)) {
        print "ERROR: column \"GOLD Analysis Project Type\" not found" > "/dev/stderr"
        exit 1
    }
    print "taxon_oid", "GOLD Analysis Project Type", "Ecosystem Type"
    next
}

{
    print $idx["taxon_oid"], $idx["GOLD Analysis Project Type"], $idx["Ecosystem Type"]
}
' "$METADATA" | sort -k1,1 > "$DIR/project_type.tmp.tsv"

# Merge: Family/BGC row, taxon id, project type, ecosystem type
join -t $'\t' -1 1 -2 1 \
  <(tail -n +2 "$BGC" | awk -F '\t' '{split($1,a,"|"); print a[1]"\t"$0}' | sort -k1,1) \
  "$DIR/project_type.tmp.tsv" \
  > "$DIR/bgc_biomes.tsv"

rm "$DIR/project_type.tmp.tsv"

echo "Wrote $DIR/bgc_biomes.tsv"
