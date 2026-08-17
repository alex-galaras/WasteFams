#!/usr/bin/env bash
# Build a DIAMOND database from the Pfam sequence database (pfamseq).
#
# Input:  $PROJECT_DIR/resources/pfam_database/pfamseq
# Output: $PROJECT_DIR/resources/pfam_database/pfamdb.dmnd
set -euo pipefail
: "${PROJECT_DIR:?Set PROJECT_DIR to your working directory, e.g. export PROJECT_DIR=~/wastefams-run}"

DIR="$PROJECT_DIR/resources/pfam_database"

diamond makedb \
  --in "$DIR/pfamseq" \
  -d "$DIR/pfamdb"

echo "Wrote $DIR/pfamdb.dmnd"
