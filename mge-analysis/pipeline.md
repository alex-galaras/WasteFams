# MGE Analysis

Identifies mobile genetic elements (MGEs) in the protein set by DIAMOND search against the [Mobile Genetic Element Database](https://github.com/KatariinaParnanen/MobileGeneticElementDatabase), classifies hits by functional class, and links classified MGEs to the protein families they appear in.

```
resources/MobileGeneticElementDatabase
   ↓
Build MGE protein DB                (build_mge_protein_db.sh)
   ↓
DIAMOND search + best-hit filter    (run_diamond_search.sh)
   ↓
Classify hits + link to families    (classify_mge_hits.sh)
   ↓
MGE class barplot                   (plot_mge_class_barplot.R)
Top-family x class barplot          (plot_family_mge_barplot.R)
```

All scripts read a `PROJECT_DIR` environment variable pointing at your working directory:

```bash
export PROJECT_DIR=~/wastefams-run
scripts/build_mge_protein_db.sh
scripts/run_diamond_search.sh
scripts/classify_mge_hits.sh
Rscript scripts/plot_mge_class_barplot.R "$PROJECT_DIR"
Rscript scripts/plot_family_mge_barplot.R "$PROJECT_DIR"
```

## Steps

### 1. Build the MGE protein database — `build_mge_protein_db.sh`

Calls genes on the [MGEdb](https://github.com/KatariinaParnanen/MobileGeneticElementDatabase) nucleotide sequences with Prodigal, then builds a DIAMOND database from the resulting proteins.

| | |
|---|---|
| **Input** | `resources/MobileGeneticElementDatabase/MGEs_FINAL_99perc_trim.fasta` |
| **Output** | `resources/MobileGeneticElementDatabase/MGEdb.dmnd` |

### 2. DIAMOND search — `run_diamond_search.sh`

| | |
|---|---|
| **Input** | `antimicrobial_resistance/fasta_chunks/*.fasta`, `resources/MobileGeneticElementDatabase/MGEdb.dmnd` |
| **Output** | `mges/all_vs_MGE.besthit.tsv` |

| Parameter | Value |
|---|---|
| `--evalue` | 1e-5 |
| `--max-target-seqs` | 10 |
| Minimum identity | 30% |
| Hits kept per query | best (highest bitscore) |

### 3. Classify hits + link to families — `classify_mge_hits.sh`

`members_link_prodigal/WWF_IMG_prodigal.tsv` (protein family members linked to their Prodigal ORF coordinates) is produced by a separate linking step that isn't part of this repository.

| | |
|---|---|
| **Input** | `mges/all_vs_MGE.besthit.tsv`, `resources/MobileGeneticElementDatabase/MGE_tax_table_trim.txt`, `members_link_prodigal/WWF_IMG_prodigal.tsv` |
| **Output** | `mges/all_vs_MGE.with_class.ALL.tsv`, `mges/mge_families.tsv` |

Unmatched hits (no entry in the MGEdb taxonomy table) are labeled `unclassified` rather than dropped.

### 4. Barplots — `plot_mge_class_barplot.R`, `plot_family_mge_barplot.R`

| | |
|---|---|
| **Input** | `mges/all_vs_MGE.with_class.ALL.tsv` (class barplot), `mges/mge_families.tsv` + `step5_hhfilter/hhfilter_members.tsv` (family barplot) |
| **Output** | `mges/mge_classes.png`, `mges/mge_families_classes.png` |

The class barplot shows overall MGE functional class frequency (classes with > 100 hits). The family barplot shows the top 12 protein families with the most MGE-classified members, stacked by class, each bar labeled `members in MGE / total family size`.

## Software

| Tool | Version |
|---|---|
| Prodigal | 2.6.3 |
| DIAMOND | latest |

R packages: `dplyr`, `ggplot2`.
