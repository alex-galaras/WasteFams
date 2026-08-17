#!/usr/bin/env Rscript
# Biome x biome z-score heatmap: how many protein families two biomes share,
# relative to each biome's own row mean/variance (so biomes with very
# different total family counts remain comparable).
#
# A family's biome assignment(s) are its Ecosystem Type(s) that account for
# > MIN_PERCENT of that family's members; each biome-pair cell in the shared
# matrix counts families present in both biomes; the matrix is then z-scored
# by row before plotting.
#
# Usage: plot_biome_zscore_heatmap.R <PROJECT_DIR>
suppressMessages({
  library(dplyr)
  library(tidyr)
  library(ComplexHeatmap)
  library(circlize)
})

args <- commandArgs(trailingOnly = TRUE)
project_dir <- args[1]
dir <- file.path(project_dir, "analysisI_biome")

MIN_PERCENT <- 5

df <- read.delim(file.path(dir, "families_ecosystems.cleaned.tsv"), header = FALSE)
colnames(df) <- c("family",
                  "dataset.id",
                  "Ecosystem",
                  "Ecosystem_Category",
                  "Ecosystem_Type",
                  "Ecosystem_Subtype",
                  "Specific_Ecosystem")

# Each family's members are spread across biomes (Ecosystem Type); keep only
# biome assignments that account for a large enough share of a family's members
eco.type.perc <- df %>%
  group_by(Family = family, Biome = Ecosystem_Type) %>%
  summarise(Count = n(), .groups = "drop_last") %>%
  mutate(Total = sum(Count),
         Percentage = 100 * Count / Total) %>%
  ungroup()

eco.type.filtered <- as.data.frame(eco.type.perc) %>%
  filter(Percentage > MIN_PERCENT)

# Presence/abundance matrix: biome x family
mat <- eco.type.filtered %>%
  group_by(Biome, Family) %>%
  summarise(n = n(), .groups = "drop") %>%
  pivot_wider(names_from = Family, values_from = n, values_fill = 0)

# Shared-families matrix between biomes (how many families both biomes have)
df_bin <- mat %>%
  mutate(across(-Biome, ~ if_else(.x > 0, 1, 0)))

mat_bin <- df_bin %>% select(-Biome) %>% as.matrix()
biomes <- df_bin$Biome
n <- length(biomes)

shared <- matrix(0, n, n, dimnames = list(biomes, biomes))
for (i in 1:n) {
  for (j in 1:n) {
    shared[i, j] <- sum(mat_bin[i, ] == 1 & mat_bin[j, ] == 1)
  }
}
rownames(shared) <- colnames(shared)

# Z-score by row for the heatmap
shared_z <- t(scale(t(shared)))

col_fun <- colorRamp2(
  c(min(shared_z), 0, max(shared_z)),
  c("#2166ac", "white", "#b2182b")
)

png(file.path(dir, "heatmap_wastewater_biome_zscore.png"), width = 3000, height = 3000, res = 300)

Heatmap(
  shared_z,
  name = "Z-score\nshared families",
  col = col_fun,
  column_title = "Biome vs. Biome",
  row_title = "Biome",
  row_names_side = "left",
  column_names_rot = 45,
  row_names_gp = gpar(fontsize = 16, fontface = "bold", col = "black"),
  column_names_gp = gpar(fontsize = 16, fontface = "bold", col = "black"),
  heatmap_legend_param = list(
    title = "Z-score",
    at = c(-2, 0, 2),
    labels = c("Low", "Mean", "High")
  )
)

dev.off()

message(sprintf("Wrote %s", file.path(dir, "heatmap_wastewater_biome_zscore.png")))
