#!/usr/bin/env Rscript
# pTM by quality-class boxplot: each model's pTM as a jittered point, with
# median and IQR summary, grouped into the same HQ/MQ/LQ tiers used
# elsewhere in this pipeline.
#
# Usage: plot_ptm_quality_boxplot.R <PROJECT_DIR>
suppressMessages({
  library(ggplot2)
  library(dplyr)
})

args <- commandArgs(trailingOnly = TRUE)
project_dir <- args[1]
structures_dir <- file.path(project_dir, "structures")

df <- read.delim(file.path(structures_dir, "metrics.tsv"))

# Define quality classes based on pTM
df <- df %>%
  mutate(
    Quality = case_when(
      pTM >= 0.7 ~ "HQ",
      pTM >= 0.5 ~ "MQ",
      TRUE       ~ "LQ"
    ),
    Quality = factor(Quality, levels = c("HQ", "MQ", "LQ"))
  )

# Count models per class (for subtitle)
counts <- df %>% count(Quality)
subtitle_text <- sprintf(
  "High: %d | Medium: %d | Low: %d",
  counts$n[counts$Quality == "HQ"],
  counts$n[counts$Quality == "MQ"],
  counts$n[counts$Quality == "LQ"]
)

p <- ggplot(df, aes(x = Quality, y = pTM, color = Quality)) +
  geom_jitter(width = 0.25, height = 0, alpha = 0.45, size = 2) +
  stat_summary(fun = median, geom = "point", shape = 18, size = 4, color = "black") +
  stat_summary(
    fun.data = function(y) {
      data.frame(y = median(y), ymin = quantile(y, 0.25), ymax = quantile(y, 0.75))
    },
    geom = "errorbar", width = 0.15, color = "black", linewidth = 0.8
  ) +
  geom_hline(yintercept = c(0.5, 0.7), linetype = "dashed", color = "grey60", linewidth = 0.6) +
  scale_color_manual(values = c("HQ" = "#1b9e77", "MQ" = "#d95f02", "LQ" = "#7570b3")) +
  coord_cartesian(ylim = c(0, 1)) +
  labs(
    title = "AlphaFold3 results",
    subtitle = subtitle_text,
    x = "Model quality class",
    y = "pTM",
    color = "Model quality"
  ) +
  theme_bw(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.title.x = element_text(face = "bold"),
    axis.title.y = element_text(face = "bold"),
    axis.text.x  = element_text(face = "bold", size = 12, color = "black"),
    axis.text.y  = element_text(face = "bold", size = 12, color = "black"),
    panel.grid.minor = element_blank(),
    legend.position = "none"
  )

out_dir <- file.path(structures_dir, "plots")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
ggsave(file.path(out_dir, "pTM_by_quality_class_median.png"), p, width = 6, height = 6, dpi = 300)

message(sprintf("Wrote %s", file.path(out_dir, "pTM_by_quality_class_median.png")))
