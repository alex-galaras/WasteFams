#!/usr/bin/env bash
# Step 1: Metadata curation.
#
# Merges the per-category IMG dataset TSVs (bioremediation, sewage treatment
# plant, solid waste, wastewater, WWTP) into one wastewater-filtered metadata
# table. The bioremediation category also contains non-wastewater
# environments, so it alone is filtered down to "Wastewater" rows first.
#
# Input:  $PROJECT_DIR/metadata/*.tsv  (one TSV per IMG category, same columns)
# Output: $PROJECT_DIR/metadata/wastewater_merged.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

cd "$PROJECT_DIR/metadata"

# Keep only the header, then only "Wastewater" rows from bioremediation.tsv
head -1 bioremediation.tsv > header.txt
grep "Wastewater" bioremediation.tsv > bioremediation_wastewater.tsv
cat header.txt bioremediation_wastewater.tsv > bioremediation_wastewater_to_use.tsv
mkdir -p bioremediation
mv bioremediation.tsv bioremediation/
rm bioremediation_wastewater.tsv

# Concatenate all category TSVs, skipping each file's repeated header row
for FILE in *.tsv
do
  tail -n +2 "$FILE" >> wastewater_merged_temp.tsv
done

cat header.txt wastewater_merged_temp.tsv > wastewater_merged.tsv
rm wastewater_merged_temp.tsv

echo "Wrote $PROJECT_DIR/metadata/wastewater_merged.tsv"
