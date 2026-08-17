# WasteFams

Here, we present WasteFams, the first comprehensive database dedicated to the systematic exploration of protein families in wastewater metagenomic and metatranscriptomic studies worldwide. Integrating data from 580 metagenomes, 132 metatranscriptomes, and 1,709 reference genomes, WasteFams catalogs 3,887 non-redundant protein families (containing ⪰100 members) derived from over 105 million predicted proteins. Each protein family is enriched with multi-layered annotations, including AlphaFold3 structural predictions, taxonomic classifications, and biome-specific metadata. To further expand their functional annotation, we integrated deep genomic context analysis to link protein families to Mobile Genetic Elements (MGEs), Biosynthetic Gene Clusters (BGCs), Antibiotic Resistance Genes (ARGs), and CRISPR elements. Accessible through the EnvoFams portal, WasteFams provides a user-friendly interface featuring advanced search capabilities, sequence and structural similarity tools, and interactive visualization modules. The database can be found in the [WasteFams](https://www.envofams.org/wastefams) portal.

## Contents

| File | Description |
|---|---|
| [protein-family-generation/](protein-family-generation/pipeline.md) | Main pipeline: dataset curation, deduplication, protein family generation (MMseqs2 linclust), MAFFT alignment, HHfilter, and exploratory length/family-size statistics. Methodology in `pipeline.md`, runnable scripts in `scripts/`. |
| [biome-distribution/](biome-distribution/pipeline.md) | Biome x biome z-score heatmap of shared protein families across wastewater ecosystem types. Methodology in `pipeline.md`, runnable scripts in `scripts/`. |
| [pfam-annotation/](pfam-annotation/pipeline.md) | Pfam annotation of family representatives via HMMER and GO term mapping (BP/MF/CC), linked back to family members and biome metadata. Methodology in `pipeline.md`, runnable scripts in `scripts/`. |
| [crispr/](crispr/pipeline.md) | CRISPR-Cas system typing (CCTyper) on wastewater scaffolds, linked to overlapping protein families. Methodology in `pipeline.md`, runnable scripts in `scripts/`. |
| [gene-neighborhood/](gene-neighborhood/pipeline.md) | Pfam annotation of gene neighborhoods via DIAMOND against the Pfam sequence database. Methodology in `pipeline.md`, runnable scripts in `scripts/`. |
| [bgc-discovery/](bgc-discovery/pipeline.md) | Biosynthetic gene cluster (BGC) discovery with antiSMASH using the [BGC Atlas](https://github.com/ZiemertLab/bgc-atlas-web) module set, BGC product/class distribution, and RiPP protein-family co-occurrence. Methodology in `pipeline.md`, runnable scripts in `scripts/`. |
| [arg-discovery/](arg-discovery/pipeline.md) | Antimicrobial resistance gene (ARG) discovery with RGI/CARD, high-confidence identity filtering, and an antibiotic-class x phylum heatmap. Methodology in `pipeline.md`, runnable scripts in `scripts/`. |
| [mge-analysis/](mge-analysis/pipeline.md) | Mobile genetic element (MGE) detection via DIAMOND against the [MGE database](https://github.com/KatariinaParnanen/MobileGeneticElementDatabase) and class/family barplots. Methodology in `pipeline.md`, runnable scripts in `scripts/`. |
| [wastewater-structures/](wastewater-structures/pipeline.md) | pTM-based quality tiers for AlphaFold3 models, Foldseek structural search against CATH/PDB/AlphaFold, and a pTM-by-quality-class boxplot. Methodology in `pipeline.md`, runnable scripts in `scripts/`. |

## Data

Small input tables referenced by more than one pipeline (or otherwise needed to get started without the original compute environment) are bundled in [`data/`](data/):

| File | Used by |
|---|---|
| `wastewater_merged.tsv` | `protein-family-generation/` (Step 1 output), `biome-distribution/`, `bgc-discovery/` |
| `wastewater_ecotype_distribution.tsv` | `pfam-annotation/` |
| `metrics.tsv` | `wastewater-structures/` (starting input; its `model_cif` column points to the original environment's AlphaFold3 output and needs updating to your own model paths) |

Large intermediate/reference files (scaffold FASTAs, taxonomic lineage tables, structural databases, the Pfam/MGE sequence databases) are not included; each pipeline's `pipeline.md` documents exactly what it expects and where.

## Software

- **MMseqs2** 18.8cc5c
- **TANTAN** 51
- **MAFFT** 7.490
- **HH-suite (hhfilter)** 3.3.0
- **Prodigal** 2.6.3
- **DIAMOND** 2.0.14
- **HMMER** (Pfam annotation) 3.3.2
- **antiSMASH** 8.0.4
- **RGI / CARD** 6.0.4 / 3.2.7
- **Foldseek** 799792f
- **bedtools** 2.30.0
- **cctyper** (CRISPR typing) 1.8.0
- R packages: `dplyr`, `tidyr`, `tibble`, `stringr`, `readr`, `ggplot2`, `scales`, `patchwork`, `ComplexUpset`, `ComplexHeatmap`, `circlize`

## Notes

These pipelines were originally run interactively against data on the authors' compute environment; paths have since been depersonalized to a single `PROJECT_DIR` variable throughout. Parameters (identity/coverage thresholds, HMMER cutoffs, MAFFT/HHfilter settings, etc.) are documented inline in each `pipeline.md`.

Each pipeline above is a methodology doc (`pipeline.md`) plus runnable, depersonalized scripts (`scripts/`), sharing one conda environment (`environment.yml`) and citation/license metadata.
