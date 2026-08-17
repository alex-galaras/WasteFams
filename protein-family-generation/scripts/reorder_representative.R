#!/usr/bin/env Rscript
# Reorders each family's rows so its representative sequence (as recorded in
# the families_100.tsv catalog from Step 4) comes first. Used by Step 5
# (4-column MAFFT output) and Step 6 (5-column HHfilter output) since
# hhfilter's -M first requires the representative to be the first sequence.
#
# Usage: reorder_representative.R <representative_tsv> <input_tsv> <output_tsv> <col_names>
#   representative_tsv: Family, RepSeq, Score (from Step 4's families_100.tsv)
#   input_tsv:           first column is Family, second is the member SeqID
#   col_names:           comma-separated column names for input_tsv, e.g.
#                        "Family,SeqID,Seq,Alignment" or
#                        "Family,SeqID,Seq,Alignment,HHmodel"

args <- commandArgs(trailingOnly = TRUE)
representative_path <- args[1]
input_path <- args[2]
output_path <- args[3]
col_names <- strsplit(args[4], ",")[[1]]

rep <- read.table(representative_path, sep = "\t", header = FALSE,
                   col.names = c("Family", "RepSeq", "Score"))

tsv <- read.table(input_path, sep = "\t", header = FALSE, col.names = col_names)

# Merge representative info into TSV
tsv$IsRep <- tsv$SeqID == rep$RepSeq[match(tsv$Family, rep$Family)]

# Order: by Family, representative first (TRUE > FALSE if reversed)
tsv_ordered <- tsv[order(tsv$Family, -tsv$IsRep), ]

write.table(tsv_ordered[, seq_along(col_names)], file = output_path,
            sep = "\t", quote = FALSE, row.names = FALSE, col.names = FALSE)
