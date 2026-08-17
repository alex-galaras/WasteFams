#!/usr/bin/env bash
# Join each protein family's members to their source dataset's IMG ecosystem
# metadata (Ecosystem, Ecosystem Category, Ecosystem Subtype, Ecosystem Type,
# Specific Ecosystem). Metagenome and isolate member ids encode their dataset
# id in different header positions, so they're extracted separately then
# concatenated.
#
# Input:  $PROJECT_DIR/step5_hhfilter/hhfilter_members.tsv
#         $PROJECT_DIR/metadata/wastewater_merged.tsv
# Output: $PROJECT_DIR/analysisI_biome/families_ecosystems.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

DIR="$PROJECT_DIR/analysisI_biome"
FAMILIES="$PROJECT_DIR/step5_hhfilter/hhfilter_members.tsv"
METADATA="$PROJECT_DIR/metadata/wastewater_merged.tsv"
mkdir -p "$DIR"

# Metagenome member ids: dataset.id is the first "|"-delimited field
# (e.g. 2044078017|TAC_GD7Y0W001DZRAC|TAC_1434630 -> dataset.id 2044078017)
cut -f1,2 "$FAMILIES" | grep -v "iso" | awk -F '\t' '{split($2, a, "|"); print $1 "\t" a[1]}' | sort -k2,2 > "$DIR/metagenomes_datasets.tsv"

# Isolate member ids: dataset.id is the second "|"-delimited field
# (e.g. iso_pr_bacteria|2264867236|2265098375| -> dataset.id 2264867236)
cut -f1,2 "$FAMILIES" | grep "iso" | awk -F '\t' '{split($2, a, "|"); print $1 "\t" a[2]}' | sort -k2,2 > "$DIR/isolates_datasets.tsv"

# Columns 27-31 of wastewater_merged.tsv are the ecosystem fields
cut -f1,27-31 "$METADATA" | sort -k1,1 > "$DIR/ecosystem_metadata.tsv"

join -t $'\t' -1 2 -2 1 \
    "$DIR/metagenomes_datasets.tsv" \
    "$DIR/ecosystem_metadata.tsv" \
| awk -F'\t' 'BEGIN{OFS="\t"} {print $2, $1, $3, $4, $5, $6, $7}' \
| sort -k1,1 \
> "$DIR/metagenomes_ecosystems.tsv"

join -t $'\t' -1 2 -2 1 \
    "$DIR/isolates_datasets.tsv" \
    "$DIR/ecosystem_metadata.tsv" \
| awk -F'\t' 'BEGIN{OFS="\t"} {print $2, $1, $3, $4, $5, $6, $7}' \
| sort -k1,1 \
> "$DIR/isolates_ecosystems.tsv"

cat "$DIR/metagenomes_ecosystems.tsv" "$DIR/isolates_ecosystems.tsv" \
| sort -k1,1 \
> "$DIR/families_ecosystems.tsv"

rm "$DIR/metagenomes_datasets.tsv" "$DIR/isolates_datasets.tsv" "$DIR/ecosystem_metadata.tsv" "$DIR/metagenomes_ecosystems.tsv" "$DIR/isolates_ecosystems.tsv"

echo "Wrote $DIR/families_ecosystems.tsv"
