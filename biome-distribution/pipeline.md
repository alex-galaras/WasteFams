# Biome Distribution

Characterizes how protein families are shared across wastewater biomes (ecosystem types), summarized as a biome x biome z-score heatmap of shared family counts.

```
Family members + IMG ecosystem metadata
   ↓
Join family <-> ecosystem metadata     (join_family_ecosystem_metadata.sh)
   ↓
Clean ecosystem labels                 (clean_ecosystem_labels.sh)
   ↓
Biome x biome z-score heatmap          (plot_biome_zscore_heatmap.R)
```

All scripts read a `PROJECT_DIR` environment variable pointing at your working directory:

```bash
export PROJECT_DIR=~/wastefams-run
scripts/join_family_ecosystem_metadata.sh
scripts/clean_ecosystem_labels.sh
Rscript scripts/plot_biome_zscore_heatmap.R "$PROJECT_DIR"
```

## Steps

### 1. Join family members to ecosystem metadata — `join_family_ecosystem_metadata.sh`

For each protein family member, looks up its source dataset's IMG ecosystem metadata (Ecosystem, Ecosystem Category, Ecosystem Subtype, Ecosystem Type, Specific Ecosystem). Metagenome and isolate member ids encode the dataset id in different header positions, so they're extracted separately then concatenated.

| | |
|---|---|
| **Input** | `step5_hhfilter/hhfilter_members.tsv`, `metadata/wastewater_merged.tsv` |
| **Output** | `analysisI_biome/families_ecosystems.tsv` |

### 2. Clean ecosystem labels — `clean_ecosystem_labels.sh`

Fills missing Ecosystem Type/Subtype with "Unclassified", normalizes a spelling variant ("anaerobic digestor" → "Anaerobic digester") and a capitalization inconsistency ("activated sludge" → "Activated Sludge") in Ecosystem Type.

| | |
|---|---|
| **Input** | `analysisI_biome/families_ecosystems.tsv` |
| **Output** | `analysisI_biome/families_ecosystems.cleaned.tsv` |

### 3. Biome x biome z-score heatmap — `plot_biome_zscore_heatmap.R`

A family is assigned to a biome (Ecosystem Type) when that biome accounts for more than `MIN_PERCENT` of the family's members — this keeps a family's biome assignment(s) meaningful rather than diluted by a handful of stray members. For each pair of biomes, counts how many families are present in both, then z-scores each biome's row so biomes with very different total family counts remain comparable in the heatmap.

| | |
|---|---|
| **Input** | `analysisI_biome/families_ecosystems.cleaned.tsv` |
| **Output** | `analysisI_biome/heatmap_wastewater_biome_zscore.png` |

| Parameter | Value |
|---|---|
| Minimum family-membership share to assign a biome | 5% |
| Heatmap color scale | diverging, blue (low) – white (0) – red (high), by z-score |

## Software

R packages: `dplyr`, `tidyr`, `ComplexHeatmap`, `circlize`.
