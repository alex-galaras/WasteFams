#!/usr/bin/env bash
# Map each family's Pfam domain to a GO id and its BP/MF/CC name, then link
# the Pfam description and molecular-function GO term back to individual
# family members via their biome metadata.
#
# Input:  $PROJECT_DIR/analysisII_pfam/fam_rep_pfam_description.tsv,
#         $PROJECT_DIR/resources/pfam_database/pfam_go_tables/pfam2go_GOid.tsv,
#         $PROJECT_DIR/resources/pfam_database/pfam_go_tables/{biological_process,molecular_function,cellular_component}_go_to_name.tsv,
#         $PROJECT_DIR/analysisI_biome/wastewater_ecotype_distribution.tsv
# Output: $PROJECT_DIR/analysisII_pfam/wastewater_fam_{BP,MF,CC}.tsv,
#         $PROJECT_DIR/analysisII_pfam/fam_biome_Description.tsv,
#         $PROJECT_DIR/analysisII_pfam/fam_biome_MF.tsv
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

DIR="$PROJECT_DIR/analysisII_pfam"
TABLE="$DIR/fam_rep_pfam_description.tsv"
GO_TABLES="$PROJECT_DIR/resources/pfam_database/pfam_go_tables"
GO_ID="$GO_TABLES/pfam2go_GOid.tsv"
BP="$GO_TABLES/biological_process_go_to_name.tsv"
MF="$GO_TABLES/molecular_function_go_to_name.tsv"
CC="$GO_TABLES/cellular_component_go_to_name.tsv"

# --- Map Pfam -> GO id ---
join -t $'\t' -1 3 -2 1 \
  <(sort -k3,3 "$TABLE") \
  "$GO_ID" \
  | awk '{print $2"\t"$3"\t"$1"\t"$4"\t"$5}' \
  > "$DIR/fam_rep_pfam_description_goid.tsv"

# --- Resolve GO id -> BP / MF / CC name ---
for pair in "BP:$BP" "MF:$MF" "CC:$CC"; do
  label="${pair%%:*}"
  ontology_table="${pair#*:}"

  join -t $'\t' -1 5 -2 1 \
    <(sort -k5,5 "$DIR/fam_rep_pfam_description_goid.tsv") \
    "$ontology_table" \
    | awk '{print $2"\t"$4"\t"$1"\t"$6}' \
    | sort -k1,1 \
    > "$DIR/wastewater_fam_${label}.tsv"

  echo "Wrote $DIR/wastewater_fam_${label}.tsv"
done

# --- Link Pfam description and molecular-function GO term back to members ---
BIOME="$PROJECT_DIR/analysisI_biome/wastewater_ecotype_distribution.tsv"

join -t $'\t' -1 1 -2 1 "$BIOME" "$TABLE" \
  | awk -F '\t' '{OFS="\t"; print $1,$2,$7,$8}' \
  > "$DIR/fam_biome_Description.tsv"

join -t $'\t' -1 1 -2 1 "$BIOME" "$DIR/wastewater_fam_MF.tsv" \
  | awk -F '\t' '{OFS="\t"; print $1,$2,$7,$8}' \
  > "$DIR/fam_biome_MF.tsv"

echo "Wrote $DIR/fam_biome_Description.tsv and $DIR/fam_biome_MF.tsv"
