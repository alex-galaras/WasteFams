# Wastewater Structures

Classifies AlphaFold3 models of protein family representatives by prediction quality (pTM), then searches each structure against reference structural databases (CATH, PDB, AlphaFold/UniProt) with Foldseek to find known structural neighbors.

Starts from `structures/metrics.tsv` (one row per family: `ID, pLDDT_mean, pTM, ipTM, ranking_score, model_cif`), already produced by an earlier AlphaFold3 metrics-collection step. It's provided in this repository at `data/metrics.tsv`; copy or symlink it to `structures/metrics.tsv` under your `PROJECT_DIR`. The AlphaFold3 model files themselves aren't included (too large) — the `model_cif` column holds paths relative to `structures/output/` (the personal machine prefix has been stripped), so place your own AlphaFold3 output there, or edit the column to point wherever your models actually live, before running `prepare_foldseek_queries.sh`.

```
structures/metrics.tsv
   ↓
Split by pTM quality (HQ/MQ/LQ)     (split_by_quality.sh)
   ↓
Prepare Foldseek queries            (prepare_foldseek_queries.sh)
   ↓
Foldseek search vs CATH/PDB/AFDB    (run_foldseek_search.sh, once per database)
   ↓
pTM by quality-class boxplot        (plot_ptm_quality_boxplot.R)
```

All scripts read a `PROJECT_DIR` environment variable pointing at your working directory:

```bash
export PROJECT_DIR=~/wastefams-run
scripts/split_by_quality.sh
scripts/prepare_foldseek_queries.sh

# Each db_path below is a pre-built foldseek database (foldseek databases / foldseek createdb).
scripts/run_foldseek_search.sh /path/to/CATH50_DB/CATH50 CATH50
scripts/run_foldseek_search.sh /path/to/PDB_2024_01/PDB_2024_01_13 PDB
scripts/run_foldseek_search.sh /path/to/alphafolddb/alphafold_uniprot50 alphafold

Rscript scripts/plot_ptm_quality_boxplot.R "$PROJECT_DIR"
```

## Steps

### 1. Split by pTM quality — `split_by_quality.sh`

| | |
|---|---|
| **Input** | `structures/metrics.tsv` |
| **Output** | `structures/structures_results/HQ.tsv`, `MQ.tsv`, `LQ.tsv` |

| Parameter | Value |
|---|---|
| High quality (HQ) | pTM ≥ 0.70 |
| Medium quality (MQ) | 0.50 ≤ pTM < 0.70 |
| Low quality (LQ) | pTM < 0.50 |

### 2. Prepare Foldseek queries — `prepare_foldseek_queries.sh`

Symlinks every model's mmCIF into one query folder as `<family_id>.cif`.

| | |
|---|---|
| **Input** | `structures/metrics.tsv` |
| **Output** | `structures/queries/<family_id>.cif`, `structures/structures_results/ALL_pairs.tsv` |

### 3. Foldseek search — `run_foldseek_search.sh <db_path> <label>`

Run once per reference database (CATH, PDB, AlphaFold/UniProt). Each run searches all query structures, then classifies which structures got a hit under three alignment tests, and reports how many HQ/MQ/LQ models (by pTM) are covered by each database.

| | |
|---|---|
| **Input** | `structures/queries/*.cif`, a pre-built foldseek database, `structures/structures_results/{HQ,MQ,LQ}.tsv` |
| **Output** | `structures/<label>_results` (alignment table), `structures/<label>_total_hits` (hit id list) |

**Alignment tests (a query counts as a hit if it satisfies any one):**

| Test | When used | What it detects |
|---|---|---|
| `alntmscore ≥ 0.5` | comparable sizes | full-domain match |
| `qlen < tlen` and `qtmscore ≥ 0.5` | query smaller | query matches part of the target |
| `qlen > tlen` and `ttmscore ≥ 0.5` | query larger | target matches part of the query |

| Parameter | Value |
|---|---|
| `--threads` | 16 |
| `--format-mode` | 4 |

### 4. pTM by quality-class boxplot — `plot_ptm_quality_boxplot.R`

Re-derives the same HQ/MQ/LQ pTM tiers directly from `metrics.tsv` and plots each model's pTM as a jittered point per class, with a median marker and IQR error bar.

| | |
|---|---|
| **Input** | `structures/metrics.tsv` |
| **Output** | `structures/plots/pTM_by_quality_class_median.png` |

## Software

| Tool | Version |
|---|---|
| Foldseek | latest |

R packages: `ggplot2`, `dplyr`.
