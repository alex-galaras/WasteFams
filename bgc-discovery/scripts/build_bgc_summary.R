#!/usr/bin/env Rscript
# Parse every antiSMASH GBK into one per-BGC summary table.
#
# Each GBK contributes one row per region/cand_cluster/protocluster/proto_core
# feature (parse_antismash_gbk.R). contig_edge is only recorded on the parent
# "region" feature, so it is filled down onto that region's child rows. The
# summary table keeps one row per protocluster, since that is the level
# antiSMASH assigns a class ("category": NRPS/PKS/RiPP/terpene/saccharide/
# other), a specific product, and a protocluster_number.
#
# start/end/core_start/core_end are the coordinates antiSMASH writes on the
# region/protocluster feature itself (not lifted to absolute scaffold
# coordinates).
#
# Usage: build_bgc_summary.R <PROJECT_DIR>
suppressMessages({
  library(dplyr)
  library(tidyr)
})

args <- commandArgs(trailingOnly = TRUE)
project_dir <- args[1]
dir <- file.path(project_dir, "bgc_discovery")

script_args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", grep("--file=", script_args, value = TRUE)))
source(file.path(script_dir, "parse_antismash_gbk.R"))

# antiSMASH writes each chunk's GBKs into its own output subdirectory, so
# collect them recursively rather than requiring a separate flattening step.
gbk_files <- list.files(
  file.path(dir, "antismash_output"),
  pattern = "region.*\\.gbk$",
  recursive = TRUE,
  full.names = TRUE
)
message("Found ", length(gbk_files), " GBK files")
bgc_table <- bind_rows(lapply(gbk_files, parse_gbk_file))

bgc_table <- bgc_table %>%
  mutate(contig_edge = ifelse(feature == "region", contig_edge, NA_character_)) %>%
  tidyr::fill(contig_edge, .direction = "down")

bgc_summary <- bgc_table %>%
  filter(feature == "protocluster") %>%
  transmute(
    contig,
    bgc_start = start,
    bgc_end = end,
    strand,
    bgc_class = category,
    product,
    core_start,
    core_end,
    contig_edge,
    protocluster_number
  )

write.table(
  bgc_summary,
  file.path(dir, "bgc_feature_summary.tsv"),
  sep = "\t", quote = FALSE, row.names = FALSE, col.names = TRUE
)

message(sprintf("Wrote %s (%d protoclusters)", file.path(dir, "bgc_feature_summary.tsv"), nrow(bgc_summary)))
