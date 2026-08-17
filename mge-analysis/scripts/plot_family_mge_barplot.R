#!/usr/bin/env Rscript
# Stacked barplot of the top 12 protein families with the most MGE-classified
# members, broken down by MGE class, with each bar labeled
# "members in MGE / total family size".
#
# Usage: plot_family_mge_barplot.R <PROJECT_DIR>
suppressMessages({
  library(dplyr)
  library(ggplot2)
})

args <- commandArgs(trailingOnly = TRUE)
project_dir <- args[1]
dir <- file.path(project_dir, "mges")

mge <- read.delim(file.path(dir, "mge_families.tsv"), header = FALSE)
fam <- read.delim(file.path(project_dir, "step5_hhfilter/hhfilter_members.tsv"), header = FALSE)

colnames(mge) <- c("qseqid", "sseqid", "pident", "length", "qlen", "slen", "evalue", "bitscore", "mge_class", "family")
mge$mge_class[mge$mge_class == "insertion_element_IS91"] <- "IS91"

fam_sizes <- fam %>% count(V1, name = "total_members")

mge_family_class <- mge %>% count(family, mge_class, name = "members_in_mge")

mge_family_totals <- mge_family_class %>%
  group_by(family) %>%
  summarise(members_in_mge = sum(members_in_mge), .groups = "drop")

family_stats <- mge_family_totals %>%
  left_join(fam_sizes, by = c("family" = "V1")) %>%
  filter(!is.na(total_members)) %>%
  mutate(
    fraction = members_in_mge / total_members,
    label = paste0(members_in_mge, " / ", total_members)
  )

top12_families <- family_stats %>%
  arrange(desc(members_in_mge)) %>%
  slice_head(n = 12) %>%
  pull(family)

# members_in_mge.x = per-class count, members_in_mge.y = per-family total
# (dplyr auto-suffixes on the join since both tables have this column)
plot_df <- mge_family_class %>%
  filter(family %in% top12_families) %>%
  left_join(
    family_stats %>% select(family, members_in_mge, total_members, fraction, label),
    by = "family"
  ) %>%
  mutate(family = factor(family, levels = unique(family[order(members_in_mge.y)])))

p <- ggplot(plot_df, aes(x = family, y = members_in_mge.x, fill = mge_class)) +
  geom_col(width = 0.75, color = "#1C2F5C") +
  geom_text(
    aes(x = family, y = members_in_mge.y, label = label),
    hjust = -0.15, size = 4, fontface = "bold", inherit.aes = FALSE
  ) +
  coord_flip() +
  scale_fill_manual(
    values = c(
      "transposase"  = "#2A9D8F",
      "IS91"         = "#E76F51",
      "integrase"    = "#577590",
      "istA13"       = "#6A994E",
      "unclassified" = "#F2C14E"
    ),
    name = "MGE functional class"
  ) +
  labs(x = "Protein family", y = "Number of MGEs", title = "Top MGE-related protein families") +
  theme_minimal(base_size = 13) +
  theme(
    axis.title.x = element_text(size = 14, face = "bold"),
    axis.title.y = element_text(size = 14, face = "bold"),
    axis.text.x  = element_text(size = 12, face = "bold", color = "black"),
    axis.text.y  = element_text(size = 12, face = "bold", color = "black"),
    plot.title   = element_text(size = 16, face = "bold"),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.title = element_text(size = 12, face = "bold"),
    legend.text  = element_text(size = 11)
  ) +
  expand_limits(y = max(plot_df$members_in_mge.y) * 1.15)

ggsave(file.path(dir, "mge_families_classes.png"), p, width = 12, height = 7, dpi = 300)

write.table(plot_df, file.path(dir, "family_mge_stats.tsv"),
            col.names = TRUE, row.names = FALSE, quote = FALSE, sep = "\t")

message(sprintf("Wrote %s", file.path(dir, "mge_families_classes.png")))
