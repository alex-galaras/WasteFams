#!/bin/bash
# Run AlphaFold3 inference on every JSON in one chunk (SLURM array, one task
# per chunk from Step 3), skipping AlphaFold3's own MSA search since each
# JSON already carries a precomputed MSA. Collects each model's confidence
# metrics into one metrics.tsv per chunk (Step 5 combines all chunks into one
# file).
#
# #SBATCH directives can't reference $PROJECT_DIR (SLURM parses them before
# the script runs) - submit this from $PROJECT_DIR/structures/, or edit
# --output/--error below to an absolute path.
#
# --array must match the chunk count Step 3 reports - set it before submitting.
#
#SBATCH -J AF3_Parallel
#SBATCH --gres=gpu:a100:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=5-00:00:00
#SBATCH --array=0-N%10
#SBATCH --output=logs/af3_par_%A_%a.out
#SBATCH --error=logs/af3_par_%A_%a.err
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

RUN_AF3="$PROJECT_DIR/resources/alphafold3/run_alphafold.py"
MODEL_DIR="$PROJECT_DIR/resources/alphafold3/model_parameters"

CHUNK_ID=$(printf "%03d" "$SLURM_ARRAY_TASK_ID")
CHUNK_FILE="$PROJECT_DIR/structures/json_chunks/chunk_${CHUNK_ID}"

OUT_ROOT="$PROJECT_DIR/structures/af3_results/chunk_${CHUNK_ID}"
METRICS_FILE="${OUT_ROOT}/metrics.tsv"

mkdir -p "$OUT_ROOT" logs

if [ ! -f "$CHUNK_FILE" ]; then
  echo "No chunk file: $CHUNK_FILE"
  exit 0
fi

# write header once
if [ ! -s "$METRICS_FILE" ]; then
  echo -e "ID\tpLDDT_mean\tpTM\tipTM\tranking_score\tmodel_cif" > "$METRICS_FILE"
fi

echo "Processing chunk_${CHUNK_ID} ($(wc -l < "$CHUNK_FILE") files)"

# helpers
getjq () {
  local key="$1"; shift
  jq -r --arg k "$key" '
    .. | .[$k]? // .[$k | ascii_downcase]? // .plddt_mean? // .pLDDT_mean? //
    .plddt?.mean? // .pLDDT?.mean? // .ptm? // .ipTM? // .iptm? // .ranking_score? // empty
  ' "$@" 2>/dev/null | awk 'NF{print; exit}'
}

mean_b() {
  local cif="$1"
  awk '/^ATOM/{sum+=$11; n++} END{ if(n>0) printf "%.2f", sum/n; }' "$cif" 2>/dev/null
}

# process each JSON in the chunk
while read -r INPUT_JSON; do
  [ -z "${INPUT_JSON:-}" ] && continue
  BASENAME=$(basename "$INPUT_JSON" .json)
  OUT_DIR="${OUT_ROOT}/${BASENAME}"

  # Skip if already done (restart-friendly)
  if [ -d "$OUT_DIR" ]; then
    echo "Skipping ${BASENAME} (exists)"
    continue
  fi
  mkdir -p "$OUT_DIR"

  echo "-> Running AF3 on ${BASENAME}"
  python "$RUN_AF3" \
    --json_path="$INPUT_JSON" \
    --model_dir="$MODEL_DIR" \
    --output_dir="$OUT_DIR" \
    --run_data_pipeline=false \
    --run_inference=true \
    > "${OUT_DIR}/run.log" 2>&1

  # Collect metrics
  SUBDIR=$(find "$OUT_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1 || echo "$OUT_DIR")
  SUMJ=$(ls "$SUBDIR"/*summary_confidences.json 2>/dev/null | head -n1 || true)
  CONFJ=$(ls "$SUBDIR"/*confidences.json 2>/dev/null | head -n1 || true)
  RANKCSV=$(ls "$SUBDIR"/ranking_scores.csv 2>/dev/null | head -n1 || true)
  CIF=$(ls "$SUBDIR"/*.cif 2>/dev/null | head -n1 || true)

  plddt="NA"; ptm="NA"; iptm="NA"; rscore="NA"

  if [ -n "$SUMJ" ]; then
    val="$(getjq pLDDT_mean "$SUMJ")"; [ -n "${val:-}" ] && plddt="$val"
    val="$(getjq ptm "$SUMJ")";        [ -n "${val:-}" ] && ptm="$val"
    val="$(getjq ipTM "$SUMJ")";       [ -n "${val:-}" ] && iptm="$val"
    [ "$iptm" = "NA" ] && val="$(getjq iptm "$SUMJ")" && [ -n "${val:-}" ] && iptm="$val"
  fi
  if [ "$plddt" = "NA" ] && [ -n "$CONFJ" ]; then
    val="$(getjq pLDDT_mean "$CONFJ")"; [ -n "${val:-}" ] && plddt="$val"
  fi
  if [ "$plddt" = "NA" ] && [ -n "$CIF" ]; then
    val="$(mean_b "$CIF")"; [ -n "${val:-}" ] && plddt="$val"
  fi
  if [ -n "$RANKCSV" ]; then
    rscore="$(awk -F, 'NR>1{for(i=1;i<=NF;i++) if($i ~ /^[0-9.+-eE]+$/){print $i; exit}}' "$RANKCSV" 2>/dev/null || true)"
    [ -z "$rscore" ] && rscore="NA"
  fi

  # Append metrics (local to this chunk; no global lock needed)
  echo -e "${BASENAME}\t${plddt}\t${ptm}\t${iptm}\t${rscore}\t${CIF:-NA}" >> "$METRICS_FILE"

done < "$CHUNK_FILE"

echo "Completed chunk_${CHUNK_ID}"
