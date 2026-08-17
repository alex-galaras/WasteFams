#!/usr/bin/env Rscript
# General family statistics plots for the paper: family member-count
# distribution (Step 4 output), average protein length per family, number
# of families vs. number of source datasets, and family size distribution
# (Step 6 output).
#
# Usage: plot_family_stats.R <PROJECT_DIR>
suppressMessages({
  library(dplyr)
  library(ggplot2)
})

args <- commandArgs(trailingOnly = TRUE)
project_dir <- args[1]
families_dir <- file.path(project_dir, "step3_protein_families")
hhfilter_dir <- file.path(project_dir, "step5_hhfilter")
stats_dir <- file.path(hhfilter_dir, "stats")
dir.create(stats_dir, showWarnings = FALSE, recursive = TRUE)

# --- Distribution of family member counts (Step 4, pre-alignment) ---
tsv.file <- read.delim(file.path(families_dir, "families_100.tsv"), header = FALSE)
ggplot(tsv.file, aes(x = V3)) +
  geom_histogram(bins = 20, fill = "skyblue", color = "black") +
  scale_x_continuous(breaks = seq(0, max(tsv.file$V2), by = 200)) +
  labs(title = "Distribution of family members", x = "Family members", y = "Count") +
  theme_minimal()
ggsave(file.path(families_dir, "family_distribution.png"))

# --- Average protein length per family (Step 6, post-HHfilter) ---
tsv.file <- read.delim(file.path(hhfilter_dir, "hhfilter_members.tsv"), header = FALSE)
tsv.file$prot_length <- nchar(tsv.file$V3)

avg_length <- tsv.file %>%
  group_by(V1) %>%
  summarise(avg_protein_length = mean(prot_length))

ggplot(avg_length, aes(x = avg_protein_length)) +
  geom_histogram(color = "black", fill = "#2C7BB6", binwidth = 200, boundary = 0) +
  geom_vline(xintercept = 35, color = "red", linetype = "dashed", size = 1.2) +
  labs(
    title = "Average Protein Length Distribution per Family",
    x = "Average Protein Length (aa)",
    y = "Number of Families"
  ) +
  scale_x_continuous(
    limits = c(35, max(avg_length$avg_protein_length)),
    breaks = seq(0, max(avg_length$avg_protein_length), by = 200)
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  theme_bw(base_size = 18) +
  theme(
    plot.title  = element_text(hjust = 0.5, face = "bold", size = 22, color = "black"),
    axis.title  = element_text(face = "bold", size = 20, color = "black"),
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold", size = 16, color = "black"),
    axis.text.y = element_text(face = "bold", size = 16, color = "black"),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  )
ggsave(file.path(stats_dir, "avg_protein_length_per_family_distribution.png"), width = 10, height = 8, dpi = 300)

# --- Number of families vs. number of source datasets ---
family_datasets <- tsv.file %>%
  transmute(family = V1, dataset = sub("^[^|]*\\|([^|]*)\\|.*$", "\\1", V2))
write.table(family_datasets, file.path(stats_dir, "family_datasets.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, col.names = FALSE)

unique_dataset_counts <- family_datasets %>%
  distinct(family, dataset) %>%
  count(family, name = "n_unique_datasets")

ggplot(unique_dataset_counts, aes(x = n_unique_datasets)) +
  geom_histogram(color = "black", fill = "#2C7BB6", bins = 20) +
  labs(
    title = "Number of Families vs Number of Datasets",
    x = "Number of Datasets",
    y = "Number of Families"
  ) +
  scale_x_continuous(breaks = seq(0, max(unique_dataset_counts$n_unique_datasets), by = 250)) +
  scale_y_continuous(expand = c(0, 0)) +
  theme_bw(base_size = 14) +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.title = element_text(face = "bold"),
    axis.text.x = element_text(face = "bold", size = 16, color = "black"),
    axis.text.y = element_text(face = "bold", size = 16, color = "black")
  )
ggsave(file.path(stats_dir, "families_vs_datasets.png"))

# --- Family size distribution (Step 6, post-HHfilter) ---
family_counts <- tsv.file %>% count(V1)

ggplot(family_counts, aes(x = n)) +
  geom_histogram(color = "black", fill = "#2C7BB6", binwidth = 100, boundary = 100) +
  labs(
    title = "Family Size Distribution",
    x = "Number of Protein Members",
    y = "Number of Families"
  ) +
  scale_x_continuous(limits = c(100, max(family_counts$n)), breaks = seq(100, max(family_counts$n), by = 100)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  theme_bw(base_size = 18) +
  theme(
    plot.title  = element_text(hjust = 0.5, face = "bold", size = 22, color = "black"),
    axis.title  = element_text(face = "bold", size = 20, color = "black"),
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold", size = 16, color = "black"),
    axis.text.y = element_text(face = "bold", size = 16, color = "black"),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  )
ggsave(file.path(stats_dir, "family_size_distribution.png"), width = 10, height = 8, dpi = 300)
