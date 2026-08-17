# BGC Discovery

Predicts biosynthetic gene clusters (BGCs) on wastewater scaffolds with antiSMASH, using the extended module set run by [BGC Atlas](https://github.com/ZiemertLab/bgc-atlas-web) so BGC calls stay comparable to that resource, then characterizes the resulting BGC class/product distribution and RiPP protein-family co-occurrence.

> Bağcı C, Nuhamunada M, Goyat H, Ladanyi C, Sehnal L, Blin K, Kautsar SA, Tagirdzhanov A, Gurevich A, Mantri S, von Mering C, Udwary D, Medema MH, Weber T, Ziemert N. **BGC Atlas: a web resource for exploring the global chemical diversity encoded in bacterial genomes.** *Nucleic Acids Research* 2025;53(D1):D618–D624. https://doi.org/10.1093/nar/gkae953

```
input_files/wastewater_scaffolds.tsv
   ↓
Filter > 5000 bp, split into ~60 Mbp chunks   (prepare_scaffolds.sh)
   ↓
antiSMASH (BGC Atlas module set)              (run_antismash.sh)
   ↓
Parse GBKs -> BGC summary table               (parse_antismash_gbk.R, build_bgc_summary.R)
   ↓
Join BGCs to biome metadata                   (join_bgc_biome_metadata.sh)
   ↓
BGC product barchart + class donut            (plot_bgc_distributions.R)
RiPP family co-occurrence upset               (filter_ripp_edges.sh, plot_ripp_family_upset.R)
```

All scripts read a `PROJECT_DIR` environment variable pointing at your working directory:

```bash
export PROJECT_DIR=~/wastefams-run
scripts/prepare_scaffolds.sh
scripts/run_antismash.sh
Rscript scripts/build_bgc_summary.R "$PROJECT_DIR"
scripts/join_bgc_biome_metadata.sh
Rscript scripts/plot_bgc_distributions.R "$PROJECT_DIR"
scripts/filter_ripp_edges.sh
Rscript scripts/plot_ripp_family_upset.R "$PROJECT_DIR"
```

## Steps

### 1. Prepare scaffolds — `prepare_scaffolds.sh`

Keeps scaffolds longer than 5000 bp (the minimum antiSMASH needs to call a cluster), then splits the result into ~60 Mbp chunks so antiSMASH can be parallelized across chunks instead of run on the full scaffold set at once.

| | |
|---|---|
| **Input** | `input_files/wastewater_scaffolds.tsv` |
| **Output** | `input_files/wastewater_scaffolds_greater5000.fasta`, `bgc_discovery/scaffold_chunks/scaffold_chunk_NNN.fasta` |

| Parameter | Value |
|---|---|
| Minimum scaffold length | 5000 bp |
| Target chunk size | 60 Mbp |

### 2. Run antiSMASH — `run_antismash.sh`

Runs antiSMASH on every chunk with the module set BGC Atlas uses, so BGC/RiPP calls are directly comparable to that resource.

| | |
|---|---|
| **Input** | `bgc_discovery/scaffold_chunks/*.fasta` |
| **Output** | `bgc_discovery/antismash_output/<chunk>/` (one antiSMASH run directory per chunk) |

| Parameter | Value |
|---|---|
| `--taxon` | bacteria |
| `--genefinding-tool` | prodigal-m |
| Modules enabled | `--clusterhmmer --asf --cc-mibig --cb-knownclusters --cb-subclusters --tigrfam --pfam2go --rre --tfbs` |
| Parallel jobs | 16 (1 CPU each) |

### 3. Parse GBKs into a BGC summary table — `parse_antismash_gbk.R`, `build_bgc_summary.R`

`parse_antismash_gbk.R` reads each region GBK's `region`/`cand_cluster`/`protocluster`/`proto_core` features (CDS features are skipped). Coordinates are the ones antiSMASH writes on each feature itself — they are not lifted to absolute scaffold coordinates. `build_bgc_summary.R` collects every GBK across all antiSMASH output chunks, fills the region-level `contig_edge` down onto that region's child features, then keeps one row per `protocluster` — the feature level antiSMASH assigns a class (`category`: NRPS/PKS/RiPP/terpene/saccharide/other), a specific `product`, and a `protocluster_number`.

| | |
|---|---|
| **Input** | `bgc_discovery/antismash_output/*/*region*.gbk` |
| **Output** | `bgc_discovery/bgc_feature_summary.tsv` (contig, bgc_start, bgc_end, strand, bgc_class, product, core_start, core_end, contig_edge, protocluster_number) |

### 4. Join BGCs to biome metadata — `join_bgc_biome_metadata.sh`

Looks up each BGC-carrying scaffold's source dataset project type and IMG ecosystem type.

| | |
|---|---|
| **Input** | `bgc_discovery/bgc_feature_summary.tsv`, `metadata/wastewater_merged.tsv` |
| **Output** | `bgc_discovery/bgc_biomes.tsv` |

### 5. BGC product and class distribution — `plot_bgc_distributions.R`

The product barchart keeps only products making up more than 2% of all called BGCs. The class donut shows the overall split across antiSMASH's six BGC categories.

| | |
|---|---|
| **Input** | `bgc_discovery/bgc_biomes.tsv` |
| **Output** | `bgc_discovery/bgc_product_distribution_barchart.png`, `bgc_discovery/bgc_distribution_donut.png` |

| Parameter | Value |
|---|---|
| Minimum product share shown | 2% of all BGCs |

### 6. RiPP protein-family co-occurrence upset — `filter_ripp_edges.sh`, `plot_ripp_family_upset.R`

Shows which protein families tend to appear together within the same RiPP BGC. `bgc_class.tsv` (BGC id → BGC class) and `edges.tsv` (BGC id, protein family, contig — one row per family found in that BGC) come from a separate BGC/protein-family co-occurrence network analysis that is **not** part of this pipeline; they are its required inputs. `filter_ripp_edges.sh` restricts both to RiPP BGCs. `plot_ripp_family_upset.R` then counts, for every pair of families, how many RiPP BGCs contain both; families are kept only if involved in a "strong" pair (co-occurring in ≥ 3 BGCs), and only BGCs containing at least one strong pair are plotted, so the UpSet plot isn't dominated by one-off co-occurrences.

| | |
|---|---|
| **Input** | `bgc_discovery/cooccurrence_network/bgc_class.tsv`, `bgc_discovery/cooccurrence_network/edges.tsv` |
| **Output** | `bgc_discovery/ripp_upset/ripp_family_upset.png` |

| Parameter | Value |
|---|---|
| Minimum pairwise co-occurrence to call a pair "strong" | 3 BGCs |

## Software

| Tool | Version |
|---|---|
| antiSMASH | 8.0.4 |

R packages: `dplyr`, `tidyr`, `ggplot2`, `scales`, `ComplexUpset`.
