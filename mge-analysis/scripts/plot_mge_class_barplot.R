#!/usr/bin/env Rscript
# Barplot of MGE functional class frequency across all classified hits.
#
# Usage: plot_mge_class_barplot.R <PROJECT_DIR>
suppressMessages({
  library(dplyr)
  library(ggplot2)
})

args <- commandArgs(trailingOnly = TRUE)
project_dir <- args[1]
dir <- file.path(project_dir, "mges")

mge <- read.delim(file.path(dir, "all_vs_MGE.with_class.ALL.tsv"), header = FALSE)
colnames(mge) <- c("qseqid", "sseqid", "pident", "length", "qlen", "slen", "evalue", "bitscore", "mge_class")

# Manually normalize a name variant
mge$mge_class[mge$mge_class == "insertion_element_IS91"] <- "IS91"

mge_counts <- mge %>%
  count(mge_class) %>%
  arrange(desc(n))

write.table(mge_counts, file.path(dir, "mge_classes.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, col.names = TRUE)

mge_plot <- mge_counts %>% filter(n > 100)

p <- ggplot(mge_plot, aes(x = reorder(mge_class, -n), y = n)) +
  geom_col(fill = "#3B5B92", color = "#1C2F5C", width = 0.75) +
  geom_text(aes(label = n), vjust = -0.3, size = 4, fontface = "bold", color = "black") +
  labs(
    x = "MGE functional class",
    y = "Number of ORFs",
    title = "Functional classes of mobile genetic elements"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.title.x = element_text(size = 14, face = "bold"),
    axis.title.y = element_text(size = 14, face = "bold"),
    axis.text.x  = element_text(size = 12, face = "bold", angle = 45, hjust = 1, color = "black"),
    axis.text.y  = element_text(size = 12, face = "bold", color = "black"),
    plot.title   = element_text(size = 16, face = "bold"),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(dir, "mge_classes.png"), p, width = 13, height = 8, dpi = 300)
message(sprintf("Wrote %s", file.path(dir, "mge_classes.png")))
