#!/usr/bin/env Rscript
# Antibiotic class x phylum heatmap: relative abundance of each drug class
# within the top N most ARG-abundant phyla.
#
# Usage: plot_antibiotic_class_phylum_heatmap.R <PROJECT_DIR>
suppressMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(stringr)
  library(ComplexHeatmap)
  library(circlize)
  library(grid)
})

args <- commandArgs(trailingOnly = TRUE)
project_dir <- args[1]
dir <- file.path(project_dir, "antimicrobial_resistance/rgi_results/analysisII")

# Parameters
TOP_GENERA <- 10
MIN_CLASS_PERCENT <- 3

df <- read.delim(file.path(dir, "rgi_taxa.tsv"), sep = "\t", header = TRUE, stringsAsFactors = FALSE)

# Extract phylum from the Taxa column (semicolon-separated lineage, 2nd element)
df_tax <- df %>%
  mutate(
    tax_split = strsplit(Taxa, ";"),
    Phylum = sapply(tax_split, function(x) {
      x <- trimws(x)
      if (length(x) >= 2) x[2] else NA
    })
  ) %>%
  filter(!is.na(Phylum), Phylum != "")

# Keep only the top N most ARG-abundant phyla
top_genera <- df_tax %>%
  count(Phylum, sort = TRUE) %>%
  slice_head(n = TOP_GENERA) %>%
  pull(Phylum)

df_tax <- df_tax %>% filter(Phylum %in% top_genera)

# Phylum x drug class relative abundance
df_long <- df_tax %>%
  separate_rows(Drug.Class, sep = ";") %>%
  mutate(Drug.Class = str_trim(Drug.Class)) %>%
  count(Phylum, Drug.Class) %>%
  group_by(Phylum) %>%
  mutate(percent = 100 * n / sum(n)) %>%
  ungroup()

# Collapse rare drug classes (< MIN_CLASS_PERCENT within their phylum)
df_long <- df_long %>%
  mutate(Drug.Class = ifelse(percent < MIN_CLASS_PERCENT, "Other (<3%)", Drug.Class)) %>%
  group_by(Phylum, Drug.Class) %>%
  summarise(percent = sum(percent), .groups = "drop")

heatmap_mat <- df_long %>%
  pivot_wider(names_from = Drug.Class, values_from = percent, values_fill = 0) %>%
  column_to_rownames("Phylum") %>%
  as.matrix()

colnames(heatmap_mat) <- gsub(" antibiotic", "", colnames(heatmap_mat))
colnames(heatmap_mat) <- gsub(" beta-lactam", "", colnames(heatmap_mat))

col_fun <- colorRamp2(
  c(0, 1, 5, 20, max(heatmap_mat)),
  c("white", "#deebf7", "#9ecae1", "#3182bd", "#08306b")
)

ht <- Heatmap(
  heatmap_mat,
  name = "Relative abundance (%)",
  col = col_fun,
  cluster_rows = TRUE,
  cluster_columns = TRUE,
  show_row_names = TRUE,
  show_column_names = TRUE,
  show_row_dend = FALSE,
  row_names_side = "left",
  column_names_rot = 45,
  row_names_gp = gpar(fontsize = 16, fontface = "bold"),
  column_names_gp = gpar(fontsize = 16, fontface = "bold"),
  column_title = "Antibiotic Classes",
  column_title_gp = gpar(fontsize = 18, fontface = "bold"),
  row_title_gp = gpar(fontsize = 18, fontface = "bold"),
  width = unit(22, "cm"),
  height = unit(18, "cm"),
  heatmap_legend_param = list(
    title = "Relative abundance (%)",
    title_gp = gpar(fontsize = 14, fontface = "bold"),
    labels_gp = gpar(fontsize = 12),
    at = c(0, 5, 10, 20, 50),
    labels = c("0", "5", "10", "20", "≥50")
  )
)

png(file.path(dir, "antibiotic_class_phylum_heatmap.png"), width = 18, height = 12, units = "in", res = 300)
draw(ht)
dev.off()

message(sprintf("Wrote %s", file.path(dir, "antibiotic_class_phylum_heatmap.png")))
