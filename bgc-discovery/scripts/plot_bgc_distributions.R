#!/usr/bin/env Rscript
# BGC product barchart and BGC class donut, both from the same BGC/biome
# table: overall distribution of BGC products (>2% of all BGCs) and the
# overall split across antiSMASH's six BGC categories.
#
# Usage: plot_bgc_distributions.R <PROJECT_DIR>
suppressMessages({
  library(dplyr)
  library(ggplot2)
  library(scales)
})

args <- commandArgs(trailingOnly = TRUE)
project_dir <- args[1]
dir <- file.path(project_dir, "bgc_discovery")

bgcs_all <- read.delim(file.path(dir, "bgc_biomes.tsv"), header = FALSE)

bgc_df <- bgcs_all %>%
  rename(
    genome_id = V1,
    contig = V2,
    bgc_start = V3,
    bgc_end = V4,
    strand = V5,
    bgc_class = V6,
    product = V7,
    core_start = V8,
    core_end = V9,
    contig_edge = V10,
    protocluster_number = V11,
    analysis = V12,
    biome = V13
  )

bgc_df$bgc_class <- factor(
  bgc_df$bgc_class,
  levels = c("NRPS", "PKS", "RiPP", "terpene", "saccharide", "other")
)

bgc_palette_soft <- c(
  NRPS       = "#8DD3C7",
  PKS        = "#B3DE69",
  RiPP       = "#80B1D3",
  terpene    = "#BC80BD",
  saccharide = "#FDB462",
  other      = "#D9D9D9"
)

# --- Product barchart ---
product_pct <- bgc_df %>%
  count(product) %>%
  mutate(pct = n / sum(n)) %>%
  filter(pct > 0.02) %>%
  arrange(desc(pct))

p_product <- ggplot(
  product_pct,
  aes(x = reorder(product, pct), y = pct)
) +
  geom_col(fill = "#80B1D3", width = 0.75) +

  geom_text(
    aes(label = percent(pct, accuracy = 0.1)),
    hjust = -0.1,
    size = 3.5,
    fontface = "bold"
  ) +

  coord_flip() +

  scale_y_continuous(
    labels = percent_format(),
    expand = expansion(mult = c(0, 0.15))
  ) +

  labs(
    x = "BGC product",
    y = "Percentage of BGCs",
    title = "Overall distribution of BGC products"
  ) +

  theme_minimal(base_size = 14) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),

    axis.title.x = element_text(size = 16, face = "bold"),
    axis.title.y = element_text(size = 18, face = "bold"),

    axis.text.x = element_text(size = 12, face = "bold", color = "black"),
    axis.text.y = element_text(size = 11, face = "bold", color = "black"),

    plot.title = element_text(size = 18, face = "bold"),
    plot.subtitle = element_text(size = 13, color = "grey30")
  )

ggsave(file.path(dir, "bgc_product_distribution_barchart.png"),
       p_product, width = 10, height = 6, dpi = 300)
message(sprintf("Wrote %s", file.path(dir, "bgc_product_distribution_barchart.png")))

# --- Class donut ---
bgc_class_pct <- bgc_df %>%
  count(bgc_class) %>%
  mutate(pct = n / sum(n))

p_class <- ggplot(bgc_class_pct, aes(x = 2, y = pct, fill = bgc_class)) +
  geom_col(width = 1, color = "white") +
  coord_polar(theta = "y") +
  xlim(0.5, 2.5) +

  geom_text(
    aes(label = percent(pct, accuracy = 1)),
    position = position_stack(vjust = 0.5),
    size = 4,
    fontface = "bold"
  ) +

  scale_fill_manual(
    values = bgc_palette_soft,
    name = "BGC class"
  ) +

  labs(
    title = "Overall distribution of BGC classes",
    subtitle = "Protein-family-derived scaffolds"
  ) +

  theme_void(base_size = 14) +
  theme(
    plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 13, hjust = 0.5),
    legend.title = element_text(size = 13, face = "bold"),
    legend.text = element_text(size = 11)
  )

ggsave(file.path(dir, "bgc_distribution_donut.png"),
       p_class, width = 10, height = 6, dpi = 300)
message(sprintf("Wrote %s", file.path(dir, "bgc_distribution_donut.png")))
