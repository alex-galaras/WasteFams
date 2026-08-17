#!/usr/bin/env Rscript
# Exploratory plots: protein length distribution of the combined
# metagenome + isolate protein set produced by Step 3.
#
# Usage: plot_protein_length.R <PROJECT_DIR>
suppressMessages({
  library(dplyr)
  library(ggplot2)
  library(patchwork)
})

args <- commandArgs(trailingOnly = TRUE)
project_dir <- args[1]
summary_dir <- file.path(project_dir, "step2_deduplication_summary")

# --- Binned bar chart (0-100, 100-200, ..., >1200) ---
tsv.file <- read.delim(file.path(summary_dir, "sequence.length.tsv"), header = FALSE)
colnames(tsv.file) <- c("protein.id", "prot_length")

breaks_vals <- seq(0, 1200, by = 100)
labels_vals <- c(paste0(seq(0, 1100, by = 100), "-", seq(100, 1200, by = 100)), ">1200")

tsv.file <- tsv.file %>%
  mutate(length_bin_factor = cut(
    prot_length,
    breaks = c(seq(0, 1200, by = 100), Inf),
    labels = labels_vals,
    right = TRUE,
    include.lowest = TRUE
  ))

ggplot(tsv.file, aes(x = length_bin_factor)) +
  geom_bar(color = "black", fill = "#2C7BB6") +
  labs(
    title = "Protein Length Distribution in Wastewater Dataset",
    x = "Protein Length (aa)",
    y = "Number of Proteins"
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  theme_bw(base_size = 18) +
  theme(
    plot.title   = element_text(hjust = 0.5, face = "bold", size = 22, color = "black"),
    axis.title   = element_text(face = "bold", size = 20, color = "black"),
    axis.text.x  = element_text(angle = 45, hjust = 1, face = "bold", size = 14, color = "black"),
    axis.text.y  = element_text(face = "bold", size = 16, color = "black"),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(summary_dir, "protein_length_distribution.png"), width = 10, height = 8, dpi = 300)

# --- Broken x-axis version (long tail of protein lengths) ---
tsv.file <- read.delim(file.path(summary_dir, "total_sequences.tsv"), header = FALSE)
tsv.file$prot_length <- nchar(tsv.file$V2)

tsv_main <- tsv.file %>% filter(prot_length <= 2800)
tsv_tail <- tsv.file %>% filter(prot_length > 2800)

p1 <- ggplot(tsv_main, aes(x = prot_length)) +
  geom_histogram(color = "black", fill = "#2C7BB6", binwidth = 100, boundary = 0) +
  labs(
    y = "Number of Proteins",
    x = "Protein Length (aa)",
    title = "Protein Length Distribution in Wastewater Dataset"
  ) +
  scale_x_continuous(breaks = seq(0, 2800, by = 200), limits = c(0, 2800)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  theme_bw(base_size = 18) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 22),
    axis.title = element_text(face = "bold", size = 20),
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold", size = 16, color = "black"),
    axis.text.y = element_text(face = "bold", size = 16, color = "black"),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  )

p2 <- ggplot(tsv_tail, aes(x = prot_length)) +
  geom_histogram(color = "black", fill = "#2C7BB6", binwidth = 500, boundary = 2000) +
  labs(y = "Number of Proteins", x = "Protein Length (aa)") +
  scale_x_continuous(breaks = seq(2800, max(tsv.file$prot_length), by = 2000)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  theme_bw(base_size = 18) +
  theme(
    axis.title = element_text(face = "bold", size = 20),
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold", size = 16, color = "black"),
    axis.text.y = element_text(face = "bold", size = 16, color = "black"),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  )

final_plot <- p1 / p2 + plot_layout(heights = c(3, 1))

ggsave(file.path(summary_dir, "protein_length_distribution_broken_axis.png"),
       final_plot, width = 12, height = 12, dpi = 300)
