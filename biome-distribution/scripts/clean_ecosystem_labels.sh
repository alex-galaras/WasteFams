#!/usr/bin/env bash
# Clean up the joined family-ecosystem table: fill missing Ecosystem
# Type/Subtype with "Unclassified", normalize a spelling variant and a
# capitalization inconsistency in Ecosystem Type, and reorder columns to
# put Ecosystem Type before Ecosystem Subtype.
#
# Input:  $PROJECT_DIR/analysisI_biome/families_ecosystems.tsv
# Output: $PROJECT_DIR/analysisI_biome/families_ecosystems.cleaned.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

DIR="$PROJECT_DIR/analysisI_biome"

awk -F'\t' '
BEGIN { OFS = "\t" }
{
    #Fix empty/whitespace-only values in columns 5 and 6
    if ($5 == "" || $5 ~ /^[[:space:]]*$/) $5 = "Unclassified"
    if ($6 == "" || $6 ~ /^[[:space:]]*$/) $6 = "Unclassified"

    #Normalize spelling and capitalization in column 6
    if (tolower($6) == "anaerobic digestor") $6 = "Anaerobic digester"
    if (tolower($6) == "activated sludge") $6 = "Activated Sludge"

    #Reorder columns: 1 2 3 4 6 5 7
    print $1, $2, $3, $4, $6, $5, $7
}' "$DIR/families_ecosystems.tsv" > "$DIR/families_ecosystems.cleaned.tsv"

echo "Wrote $DIR/families_ecosystems.cleaned.tsv"
