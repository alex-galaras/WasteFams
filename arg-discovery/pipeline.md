# ARG Discovery

Identifies antimicrobial resistance genes (ARGs) in the protein set with RGI/CARD, applies a high-confidence identity filter per resistance mechanism, and characterizes the taxonomic distribution of resistance mechanisms with an antibiotic-class x phylum heatmap.

```
Prodigal proteins
   ↓
RGI / CARD                         (run_rgi.sh)
   ↓
High-confidence filtering          (filter_confident_args.R)
   ↓
Scaffold id + taxonomy join        (get_scaffold_id.sh, join_arg_taxonomy.sh)
   ↓
Antibiotic class x phylum heatmap  (plot_antibiotic_class_phylum_heatmap.R)
```

All scripts read a `PROJECT_DIR` environment variable pointing at your working directory:

```bash
export PROJECT_DIR=~/wastefams-run
scripts/run_rgi.sh
Rscript scripts/filter_confident_args.R "$PROJECT_DIR"
scripts/get_scaffold_id.sh
scripts/join_arg_taxonomy.sh
Rscript scripts/plot_antibiotic_class_phylum_heatmap.R "$PROJECT_DIR"
```

## Steps

### 1. Run RGI/CARD — `run_rgi.sh`

Runs RGI's `main` mode against the CARD database on every protein FASTA chunk (Prodigal-called proteins), then merges the per-chunk outputs into one summary table.

| | |
|---|---|
| **Input** | `antimicrobial_resistance/fasta_chunks/*.fasta` |
| **Output** | `antimicrobial_resistance/rgi_results/rgi_summary.tsv` |

| Parameter | Value |
|---|---|
| RGI version | 6.0.4 |
| `--alignment_tool` | diamond |
| `--input_type` | protein |
| `-g` (gene caller) | PRODIGAL |
| `--num_threads` | 8 |

### 2. High-confidence ARG filtering — `filter_confident_args.R`

RGI/CARD hits vary widely in reliability depending on resistance mechanism and CARD model type (protein homolog model / PHM, protein variant model / PVM, protein overexpression model / OEM). Each (mechanism × model) group's identity distribution was inspected, and a per-group identity threshold was chosen from where the distribution separates a credible high-identity cluster from a low-identity noise tail. Combined-mechanism entries (semicolon-separated `Resistance Mechanism`, e.g. "target alteration; efflux") are excluded from the confident set because they can't be unambiguously assigned to one mechanism tier.

| | |
|---|---|
| **Input** | `antimicrobial_resistance/rgi_results/rgi_summary.tsv` |
| **Output** | `antimicrobial_resistance/rgi_results/analysisII/rgi_filtered.tsv`, `analysisII/confident_filter_summary.csv` |

**Filtering rationale:**

| Mechanism | Model | Threshold | Rationale |
|-----------|-------|-----------|-----------|
| Antibiotic inactivation | PHM | ≥ 60 % | Distribution is unimodal and centred well above 50 %; the low-identity tail represents divergent homologues that are still credibly enzymatic |
| Antibiotic target replacement | PHM | Keep all | Small category; distribution sits at high identity with no low-identity noise mass |
| Antibiotic target protection | PHM | ≥ 70 % | Clear separation between the true-positive cluster and a low-identity shoulder |
| Antibiotic target alteration | PVM | ≥ 70 % | PVM requires a specific variant; ≥ 70 % ensures the variant call is supported by sufficient alignment quality |
| Antibiotic target alteration | PHM | ≥ 95 % | The dominant category (> 550k hits) contains a massive low-identity peak driven by housekeeping genes with broad homology; only near-identical matches are retained |
| Antibiotic efflux | PHM | **Exclude entirely** | Distribution is broad and low-median; the vast majority are housekeeping pumps (MFS, RND, ABC) with no credible ARG assignment at these identity levels |
| Antibiotic efflux | OEM | Keep all | Overexpression-model hits represent confirmed pump over-producers; identity thresholds don't apply to expression-level resistance |
| Reduced permeability | PHM | Keep all | Very small category (n = 222 pure); all retained for completeness |

OEM entries are kept unconditionally regardless of mechanism tag, combined or pure — overexpression-based resistance is independent of sequence divergence, so the identity thresholds and combined-entry exclusion don't apply to them.

### 3. Scaffold id + taxonomy join — `get_scaffold_id.sh`, `join_arg_taxonomy.sh`

Derives each ARG hit's scaffold-level contig id from its Prodigal ORF header, then joins that to the scaffold's taxonomic lineage.

`taxonomy/filtered_WW_scaffolds_taxon_lineage` is produced by a taxonomic-assignment pipeline that isn't part of this repository — supply your own scaffold-lineage table at that path.

| | |
|---|---|
| **Input** | `antimicrobial_resistance/rgi_results/analysisII/rgi_filtered.tsv`, `taxonomy/filtered_WW_scaffolds_taxon_lineage` |
| **Output** | `antimicrobial_resistance/rgi_results/analysisII/rgi_taxa.tsv` |

### 4. Antibiotic class x phylum heatmap — `plot_antibiotic_class_phylum_heatmap.R`

For the top-N most ARG-abundant phyla, computes each drug class's relative abundance within that phylum and plots it as a clustered heatmap.

| | |
|---|---|
| **Input** | `antimicrobial_resistance/rgi_results/analysisII/rgi_taxa.tsv` |
| **Output** | `antimicrobial_resistance/rgi_results/analysisII/antibiotic_class_phylum_heatmap.png` |

| Parameter | Value |
|---|---|
| Top phyla shown | 10 |
| Minimum drug-class share to avoid collapsing into "Other" | 3% (per phylum) |

## Software

| Tool | Version |
|---|---|
| RGI | 6.0.4 |
| CARD | latest |

R packages: `dplyr`, `tidyr`, `tibble`, `stringr`, `readr`, `ComplexHeatmap`, `circlize`.
