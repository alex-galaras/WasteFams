#!/usr/bin/env Rscript
# UpSet plot of protein-family co-occurrence within RiPP BGCs: which protein
# families tend to show up together in the same RiPP biosynthetic gene
# cluster. Restricted to families involved in at least one "strong"
# co-occurrence (a pair seen together in >= 3 BGCs), otherwise every rarely
# co-occurring family would clutter the plot.
#
# Usage: plot_ripp_family_upset.R <PROJECT_DIR>
suppressMessages({
  library(dplyr)
  library(tidyr)
  library(ComplexUpset)
  library(ggplot2)
})

args <- commandArgs(trailingOnly = TRUE)
project_dir <- args[1]
dir <- file.path(project_dir, "bgc_discovery/ripp_upset")

edges <- read.delim(file.path(dir, "edges_ripp.tsv"), header = FALSE)
colnames(edges) <- c("bgc", "family", "contig")

# One family per BGC only once
pa <- unique(edges[, c("bgc", "family")])

pairs <- pa %>%
  split(.$bgc) %>%
  lapply(function(df) {
    fams <- sort(unique(df$family))
    if (length(fams) < 2) return(NULL)
    cmb <- t(combn(fams, 2))
    data.frame(f1 = cmb[, 1], f2 = cmb[, 2], stringsAsFactors = FALSE)
  }) %>%
  bind_rows()

# Count co-occurrence frequency
cooccur <- pairs %>%
  count(f1, f2, name = "weight") %>%
  arrange(desc(weight))

# Strong pairs: seen together in >= 3 BGCs
co_strong <- cooccur %>% filter(weight >= 3)

# Keep top families based on co-occurrence
top_fams <- unique(c(co_strong$f1, co_strong$f2))

# Presence/absence matrix (BGC x family)
mat <- pa %>%
  mutate(present = 1) %>%
  pivot_wider(names_from = family, values_from = present, values_fill = 0)

mat2 <- as.matrix(mat[, -1])
rownames(mat2) <- mat$bgc

# Restrict to families involved in a strong co-occurrence
mat2_focus <- mat2[, colnames(mat2) %in% top_fams, drop = FALSE]

# Keep only BGCs that contain at least one strong pair
bgc_split <- split(pa, pa$bgc)
strong_keys <- paste(co_strong$f1, co_strong$f2, sep = "___")

bgc_has_strong_pair <- sapply(bgc_split, function(df) {
  fams <- sort(unique(df$family))
  if (length(fams) < 2) return(FALSE)
  cmb <- t(combn(fams, 2))
  keys <- paste(cmb[, 1], cmb[, 2], sep = "___")
  any(keys %in% strong_keys)
})

bgcs_keep <- names(bgc_has_strong_pair)[bgc_has_strong_pair]

mat2_focus <- mat2[
  rownames(mat2) %in% bgcs_keep,
  colnames(mat2) %in% top_fams,
  drop = FALSE
]

df_focus <- as.data.frame(mat2_focus)

bold_theme <- theme(
  axis.text   = element_text(size = 20, face = "bold", color = "black"),
  axis.title  = element_text(size = 22, face = "bold", color = "black"),
  plot.title  = element_text(face = "bold", color = "black"),
  strip.text  = element_text(size = 20, face = "bold", color = "black"),
  text        = element_text(size = 20, face = "bold", color = "black")
)

png(
  file.path(dir, "ripp_family_upset.png"),
  width = 6200,
  height = 6000,
  res = 300
)

p <- upset(
  df_focus,
  intersect = colnames(df_focus),
  sort_sets = "descending",
  sort_intersections_by = "cardinality",
  base_annotations = list(
    "Intersection size" = intersection_size(
      counts = TRUE,
      text = list(size = 8, fontface = "bold", vjust = -0.5, color = "black")
    ) +
      ylab("Intersection Size") +
      bold_theme
  ),
  set_sizes = (
    upset_set_size() +
      ylab("Set Size") +
      bold_theme
  ),
  themes = upset_modify_themes(list(
    "default" = theme(
      axis.text   = element_text(size = 24, face = "bold", color = "black"),
      axis.title  = element_text(size = 22, face = "bold", color = "black"),
      text        = element_text(size = 22, face = "bold", color = "black")
    ),
    "intersections_matrix" = theme(
      axis.text.y = element_text(size = 24, face = "bold", color = "black"),
      text        = element_text(size = 22, face = "bold", color = "black")
    ),
    "overall_sizes" = theme(
      axis.text   = element_text(size = 20, face = "bold", color = "black"),
      text        = element_text(size = 20, face = "bold", color = "black")
    )
  ))
)

print(p)
dev.off()

message(sprintf("Wrote %s", file.path(dir, "ripp_family_upset.png")))
