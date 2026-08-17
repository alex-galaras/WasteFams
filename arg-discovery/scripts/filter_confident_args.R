#!/usr/bin/env Rscript
# High-confidence ARG filtering.
#
# Per-(mechanism x model) identity thresholds, chosen from the shape of each
# group's identity distribution (see pipeline.md for the full rationale
# table). Combined-mechanism entries (semicolon-separated `Resistance
# Mechanism`) are excluded from the confident set because they cannot be
# unambiguously assigned to a single mechanism tier.
#
# Usage: filter_confident_args.R <PROJECT_DIR>
suppressMessages({
  library(dplyr)
  library(stringr)
  library(readr)
})

args <- commandArgs(trailingOnly = TRUE)
project_dir <- args[1]
out_dir <- file.path(project_dir, "antimicrobial_resistance/rgi_results/analysisII")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

rgi <- read_tsv(
  file.path(project_dir, "antimicrobial_resistance/rgi_results/rgi_summary.tsv"),
  col_types = cols(
    Best_Identities                           = col_double(),
    `Percentage Length of Reference Sequence` = col_double(),
    Pass_Bitscore                             = col_double(),
    Best_Hit_Bitscore                         = col_double(),
    .default                                  = col_character()
  ),
  quote = ""
)
message(sprintf("Total hits loaded: %s", nrow(rgi)))

# OEM entries are kept unconditionally (combined or pure). Resistance via
# overexpression is independent of sequence divergence, so identity thresholds
# and the combined-entry exclusion do not apply. The 2,604 combined OEM entries
# dropped by an earlier implementation were restored here.
rgi_confident <- rgi %>%
  filter(
    # OEM: keep every entry unconditionally
    Model_type == "protein overexpression model" |

    # PHM / PVM: exclude combined entries, then apply thresholds
    (
      !str_detect(`Resistance Mechanism`, ";") &
      (
        # Antibiotic inactivation PHM  >= 60 %
        (`Resistance Mechanism` == "antibiotic inactivation" &
           Model_type == "protein homolog model" &
           Best_Identities >= 60) |

        # Antibiotic target replacement PHM  - keep all
        (`Resistance Mechanism` == "antibiotic target replacement" &
           Model_type == "protein homolog model") |

        # Antibiotic target protection PHM  >= 70 %
        (`Resistance Mechanism` == "antibiotic target protection" &
           Model_type == "protein homolog model" &
           Best_Identities >= 70) |

        # Antibiotic target alteration PVM  >= 70 %
        (`Resistance Mechanism` == "antibiotic target alteration" &
           Model_type == "protein variant model" &
           Best_Identities >= 70) |

        # Antibiotic target alteration PHM  >= 95 %
        (`Resistance Mechanism` == "antibiotic target alteration" &
           Model_type == "protein homolog model" &
           Best_Identities >= 95) |

        # Reduced permeability PHM  - keep all
        (`Resistance Mechanism` == "reduced permeability to antibiotic" &
           Model_type == "protein homolog model")
        # Antibiotic efflux PHM intentionally omitted -> excluded entirely
      )
    )
  )

# Summary of what was retained
retain_summary <- rgi_confident %>%
  count(`Resistance Mechanism`, Model_type, name = "n_retained") %>%
  left_join(
    rgi %>% count(`Resistance Mechanism`, Model_type, name = "n_total"),
    by = c("Resistance Mechanism", "Model_type")
  ) %>%
  mutate(pct_retained = round(100 * n_retained / n_total, 1)) %>%
  arrange(desc(n_retained))

write_csv(retain_summary, file.path(out_dir, "confident_filter_summary.csv"))
write_tsv(rgi_confident, file.path(out_dir, "rgi_filtered.tsv"))

message(sprintf("Total hits before filtering : %s", nrow(rgi)))
message(sprintf("Confident hits retained     : %s (%.1f %%)",
                nrow(rgi_confident), 100 * nrow(rgi_confident) / nrow(rgi)))
print(retain_summary, n = Inf)
