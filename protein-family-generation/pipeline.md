# Protein Family Generation

Builds a catalog of protein families (≥ 100 members) from wastewater-associated metagenomes and isolate genomes (IMG/GOLD).

```
IMG/GOLD
   ↓
Metadata curation            (step1_metadata.sh)
   ↓
Metagenome deduplication     (step2_deduplication.sh)
   ↓
Isolate filtering            (step3_filtering.sh)
   ↓
30% / 80% clustering         (step4_families.sh)
   ↓
≥100-member families
   ↓
MAFFT alignment              (step5_alignment.sh)
   ↓
HHfilter + trimming          (step6_hhfilter.sh)
   ↓
Final protein-family catalog (hhfilter_members.tsv, trimming_output.tsv)
```

All scripts read a `PROJECT_DIR` environment variable pointing at your working directory, and are meant to be run in order:

```bash
export PROJECT_DIR=~/wastefams-run
scripts/step1_metadata.sh
scripts/step2_deduplication.sh
scripts/step3_filtering.sh
scripts/step4_families.sh
scripts/step5_alignment.sh
scripts/step6_hhfilter.sh
```

## Steps

### 1. Metadata curation — `step1_metadata.sh`

Merges the per-category IMG dataset TSVs (bioremediation, sewage treatment plant, solid waste, wastewater, WWTP) into one wastewater-filtered metadata table. The bioremediation category also covers non-wastewater environments, so it alone is filtered down to "Wastewater" rows before merging.

| | |
|---|---|
| **Input** | `metadata/*.tsv` (one TSV per IMG category) |
| **Output** | `metadata/wastewater_merged.tsv` |

The resulting file, `wastewater_merged.tsv`, is provided in this repository at `data/wastewater_merged.tsv` — copy or symlink it to `metadata/wastewater_merged.tsv` under your `PROJECT_DIR` to skip straight to Step 2.

Metagenome scaffolds/proteins and isolate proteins were obtained as separate FASTA/TSV exports (see Steps 2 and 3). Metagenomes had already been filtered by IMG using four internal quality criteria; isolates required the length/complexity filtering in Step 3.

### 2. Metagenome deduplication — `step2_deduplication.sh`

1. Counts proteins per taxon in the raw metagenome protein FASTA.
2. Links each taxon to its GOLD sequencing ID and keeps one dataset per unique ID (the one with the most proteins).
3. Filters the FASTA down to those unique GOLD-linked taxa.
4. Collapses 100%-identical sequences with MMseqs2 linclust.

| | |
|---|---|
| **Input** | `metagenomes/stepI_fasta_filtering/Wastewater_Metag.fasta`, `metadata/wastewater_merged.tsv` |
| **Output** | `metagenomes/stepI_fasta_filtering/final_metag_filtered.fa` |

| Parameter | Value |
|---|---|
| MMseqs2 linclust `-c` (coverage) | 1 (100%) |
| MMseqs2 linclust `--min-seq-id` | 1 (100%) |

### 3. Isolate filtering — `step3_filtering.sh`

1. Keeps isolate proteins ≥ 35 aa.
2. TANTAN low-complexity filtering: sequences with fewer than 10 consecutive Xs are kept unchanged; sequences with 10 or more consecutive Xs have the Xs stripped and are kept only if the remaining sequence is still ≥ 35 aa.
3. Merges the surviving isolate proteins with the deduplicated metagenome proteins from Step 2.

| | |
|---|---|
| **Input** | `isolates/Wastewater_Iso.fasta`, `metagenomes/stepI_fasta_filtering/final_metag_filtered.fa` |
| **Output** | `step2_deduplication_summary/total_sequences.fasta` / `.tsv` |

| Parameter | Value |
|---|---|
| Minimum protein length | 35 aa |
| TANTAN consecutive-X threshold | 10 |

Exploratory plots of the resulting protein-length distribution (`plot_protein_length.R`) are saved to `step2_deduplication_summary/`.

**Dataset overview after filtering:**

|    Metagenomes    |          |             |             |         |        |                |
|:-----------------:|:--------:|:-----------:|:-----------:|---------|--------|----------------|
|                   | Datasets |  Scaffolds  |   Proteins  |         |        |                |
|        All        |    712   | 101,498,268 | 101,498,268 |         |        |                |
| Gold ID filtering |    661   |  30,351,478 |  92,641,733 |         |        |                |
|  mmseq2 linclust  |    661   |  24,468,459 |  56,092,976 |         |        |                |

|     Isolates      |          |             |             |         |        |                |
|                   |   Total  |  Bacteria   |   Archaea   | eukarya | virus  | Total proteins |
|        All        |   1,652  |    1,071    |      71     |    4    |   506  |    4,300,575   |
|      ≥ 35aa       |   1,652  |    1,071    |      71     |    4    |   506  |    4,300,475   |
|       Tantan      |   1,652  |    1,071    |      71     |    4    |   506  |    4,289,429   |

### 4. Protein family generation — `step4_families.sh`

Clusters the combined protein set into families with MMseqs2 linclust, keeps families with ≥ 100 members, and assigns them `WWF00001`, `WWF00002`... names sorted by representative sequence id.

| | |
|---|---|
| **Input** | `step2_deduplication_summary/total_sequences.fasta` / `.tsv` |
| **Output** | `step3_protein_families/families_100.tsv`, `families_sequences.tsv` |

| Parameter | Value |
|---|---|
| MMseqs2 linclust `--min-seq-id` | 0.3 (30% identity) |
| MMseqs2 linclust `-c` (coverage) | 0.8 (80%) |
| Minimum family size | 100 members |

The family member-count distribution (`plot_family_stats.R`) is saved to `step3_protein_families/family_distribution.png`.

### 5. MAFFT alignment — `step5_alignment.sh`

Splits families into chunks of 1000 and aligns each with MAFFT via `mafft_parallel_controlled.py`, which extracts each cluster's sequences into a FASTA, aligns it, and merges the aligned sequences back into the TSV rows (6 chunk files at a time, 5 CPUs each by default). Sequences containing the selenocysteine (U) amino acid are dropped by MAFFT and need `--anysymbol` to align. Rows are then reordered so each family's representative sequence comes first (`reorder_representative.R`), which HHfilter's `-M first` in Step 6 requires.

| | |
|---|---|
| **Input** | `step3_protein_families/families_sequences.tsv` |
| **Output** | `step4_maft/mafft_aligned_final.tsv` |

### 6. HHfilter and trimming — `step6_hhfilter.sh`

1. Splits aligned families into chunks of 1000 and filters each with `hhfilter_parallel_30cores.py`, which runs `hhfilter -M first -id 95 -cov 70` per cluster (up to 40 clusters in parallel).
2. Re-derives families with ≥ 100 surviving members, and restores any members HHfilter dropped from families that still qualify.
3. Trims alignment columns to the representative sequence's non-gap positions with `alignment_trimmer_15.py` (30 chunk files in parallel).

| | |
|---|---|
| **Input** | `step4_maft/mafft_aligned_final.tsv` |
| **Output** | `step5_hhfilter/hhfilter_members.tsv` (final family catalog), `step5_hhfilter/trimming_output.tsv` (trimmed alignments) |

| Parameter | Value |
|---|---|
| HHfilter `-id` | 95% identity |
| HHfilter `-cov` | 70% coverage |
| HHfilter `-M` | first (representative sequence) |
| Minimum family size (post-filter) | 100 members |

General statistics plots for the paper (average protein length per family, families vs. number of source datasets, family size distribution) are produced by `plot_family_stats.R` and saved to `step5_hhfilter/stats/`.

**Results after HHfilter:**

|                | Metagenomes |           |           |           |        |
|----------------|:-----------:|:---------:|:---------:|:---------:|--------|
|                |             |  Datasets | Scaffolds |  Proteins |        |
|                |     All     |    646    |  868,954  | 1,156,317 |        |
|                |             |           |           |           |        |
|    Isolates    |             |           |           |           |        |
|                |    Total    | Bacteria  |  Archaea  |  eukarya  | virus  |
|       All      |   167,719   |  166,390  |   1,172   |    146    |   11   |
|                |             |           |           |           |        |
|    Families    |    14462    |           |           |           |        |
| Total proteins |   1324036   |           |           |           |        |

## Software

| Tool | Version |
|---|---|
| MMseqs2 | 18.8cc5c |
| TANTAN | 51 |
| MAFFT | latest |
| HH-suite (hhfilter) | 3.3.0 |

R packages: `dplyr`, `ggplot2`, `patchwork`.
