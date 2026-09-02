#!/usr/bin/env bash
# Build one FASTA per family from its trimmed, aligned member sequences (gap
# characters preserved), for use as a precomputed MSA in the AlphaFold3 input
# JSON (Step 2).
#
# Input:  $PROJECT_DIR/step5_hhfilter/trimming_output.tsv
#         (5 columns: FamID, MemberID, Seq, AlignedSeq, TrimmedSeq)
# Output: $PROJECT_DIR/structures/fasta_for_structures/<FamID>.fa
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

INFILE="$PROJECT_DIR/step5_hhfilter/trimming_output.tsv"
OUTDIR="$PROJECT_DIR/structures/fasta_for_structures"
mkdir -p "$OUTDIR"

awk -F'\t' -v OUTDIR="$OUTDIR" '
NF>=5 && $1 && $2 && $5 {
    cluster = $1
    header = $2
    seq = $5

    # Remove stop codons and whitespace
    gsub(/\*/, "", seq)
    gsub(/[ \t\r\n]/, "", seq)

    outfile = OUTDIR "/" cluster ".fa"
    print ">" header >> outfile
    print seq >> outfile
    close(outfile)
}' "$INFILE"

echo "Wrote per-family FASTAs to $OUTDIR"
