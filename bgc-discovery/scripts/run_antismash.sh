#!/usr/bin/env bash
# Run antiSMASH on every scaffold chunk with the extended module set used by
# BGC Atlas (https://github.com/ZiemertLab/bgc-atlas-web), so BGC calls stay
# comparable to that resource:
#   Bagci C, et al. BGC Atlas: a web resource for exploring the global
#   chemical diversity encoded in bacterial genomes. Nucleic Acids Research
#   2025;53(D1):D618-D624. https://doi.org/10.1093/nar/gkae953
#
# Input:  $PROJECT_DIR/bgc_discovery/scaffold_chunks/*.fasta
# Output: $PROJECT_DIR/bgc_discovery/antismash_output/<chunk>/
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

INPUT_DIR="$PROJECT_DIR/bgc_discovery/scaffold_chunks"
OUTPUT_DIR="$PROJECT_DIR/bgc_discovery/antismash_output"
mkdir -p "$OUTPUT_DIR"

ls "$INPUT_DIR"/*.fasta | \
parallel -j 16 --memfree 16G --joblog "$OUTPUT_DIR/antismash_joblog.txt" '
  sample=$(basename {} .fasta)
  antismash {} \
    --output-dir '"$OUTPUT_DIR"'/$sample \
    --taxon bacteria \
    --genefinding-tool prodigal-m \
    --clusterhmmer \
    --asf \
    --cc-mibig \
    --cb-knownclusters \
    --cb-subclusters \
    --tigrfam \
    --pfam2go \
    --rre \
    --tfbs \
    --cpus 1
'

echo "antiSMASH output in $OUTPUT_DIR"
