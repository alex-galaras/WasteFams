# Wastewater Structures

Predicts a structure for every protein family's representative with AlphaFold3 (using each family's own trimmed alignment as a precomputed MSA, so AlphaFold3's own genetic-search pipeline is skipped), classifies the resulting models by prediction quality (pTM), then searches each structure against reference structural databases (CATH, PDB, AlphaFold/UniProt) with Foldseek to find known structural neighbors.

```
step5_hhfilter/trimming_output.tsv
   ↓
Per-family FASTA (trimmed MSA)          (build_family_fastas.sh)
   ↓
AlphaFold3 input JSON                   (build_af3_json.py)
   ↓
Chunk JSON list for array submission    (chunk_af3_jsons.sh)
   ↓
AlphaFold3 inference (SLURM array)      (run_alphafold3.sh)
   ↓
Combine per-chunk metrics               (combine_af3_metrics.sh)
   ↓
structures/metrics.tsv
   ↓
Split by pTM quality (HQ/MQ/LQ)         (split_by_quality.sh)
   ↓
Prepare Foldseek queries                (prepare_foldseek_queries.sh)
   ↓
Foldseek search vs CATH/PDB/AFDB        (run_foldseek_search.sh, once per database)
   ↓
pTM by quality-class boxplot            (plot_ptm_quality_boxplot.R)
```

If you don't want to (re)run the AlphaFold3 steps yourself, a copy of `metrics.tsv` from the original run is bundled at `data/metrics.tsv` — copy or symlink it to `structures/metrics.tsv` under your `PROJECT_DIR` and start at Step 6. The AlphaFold3 model files themselves aren't included (too large) — the bundled `metrics.tsv`'s `model_cif` column holds paths relative to `structures/output/` (the personal machine prefix has been stripped), so place your own AlphaFold3 output there, or edit the column to point wherever your models actually live, before running `prepare_foldseek_queries.sh`.

All scripts read a `PROJECT_DIR` environment variable pointing at your working directory:

```bash
export PROJECT_DIR=~/wastefams-run
scripts/build_family_fastas.sh
python3 scripts/build_af3_json.py "$PROJECT_DIR"
scripts/chunk_af3_jsons.sh

# Set --array in run_alphafold3.sh to match the chunk count chunk_af3_jsons.sh
# reports, then submit from $PROJECT_DIR/structures/:
sbatch ../wastewater-structures/scripts/run_alphafold3.sh

scripts/combine_af3_metrics.sh
scripts/split_by_quality.sh
scripts/prepare_foldseek_queries.sh

# Each db_path below is a pre-built foldseek database (foldseek databases / foldseek createdb).
scripts/run_foldseek_search.sh /path/to/CATH50_DB/CATH50 CATH50
scripts/run_foldseek_search.sh /path/to/PDB_2024_01/PDB_2024_01_13 PDB
scripts/run_foldseek_search.sh /path/to/alphafolddb/alphafold_uniprot50 alphafold

Rscript scripts/plot_ptm_quality_boxplot.R "$PROJECT_DIR"
```

## Steps

### 1. Per-family FASTA — `build_family_fastas.sh`

Builds one FASTA per family from its trimmed, aligned member sequences (gap characters preserved), which doubles as that family's precomputed MSA for Step 2.

| | |
|---|---|
| **Input** | `step5_hhfilter/trimming_output.tsv` (FamID, MemberID, Seq, AlignedSeq, TrimmedSeq) |
| **Output** | `structures/fasta_for_structures/<FamID>.fa` |

### 2. AlphaFold3 input JSON — `build_af3_json.py`

For each family FASTA, uses the first (representative) sequence, ungapped, as the query, and the whole FASTA file (gaps included) as a precomputed `unpairedMsa` — so AlphaFold3 uses the family's own alignment instead of running its own MSA search.

| | |
|---|---|
| **Input** | `structures/fasta_for_structures/*.fa` |
| **Output** | `structures/json_files/<FamID>.json` |

### 3. Chunk the JSON list — `chunk_af3_jsons.sh`

Lists every input JSON and splits the list into fixed-size chunks, one chunk per SLURM array task in Step 4.

| | |
|---|---|
| **Input** | `structures/json_files/*.json` |
| **Output** | `structures/json_chunks/chunk_NNN` |

| Parameter | Value |
|---|---|
| Families per chunk | 2 |

### 4. AlphaFold3 inference — `run_alphafold3.sh`

A SLURM array job: each task runs AlphaFold3 on every JSON in its chunk (skipping AlphaFold3's own MSA search, since the JSON already carries one), then extracts each model's pLDDT/pTM/ipTM/ranking-score into that chunk's own `metrics.tsv` (falling back to the mean per-atom B-factor of the model's mmCIF as a pLDDT proxy if the confidence JSON isn't found). Restart-friendly: a family already present as an output directory is skipped.

`--array` must be set to match the chunk count Step 3 reports before submitting, and `#SBATCH --output`/`--error` can't reference `$PROJECT_DIR` (SLURM parses `#SBATCH` directives before the script runs) — submit from `$PROJECT_DIR/structures/`, or edit those two paths directly.

| | |
|---|---|
| **Input** | `structures/json_chunks/chunk_<NNN>`, `resources/alphafold3/run_alphafold.py`, `resources/alphafold3/model_parameters` |
| **Output** | `structures/af3_results/chunk_<NNN>/<FamID>/` (AlphaFold3 output), `structures/af3_results/chunk_<NNN>/metrics.tsv` |

| Parameter | Value |
|---|---|
| GPU | 1x A100 |
| `--cpus-per-task` | 4 |
| `--mem` | 32G |
| `--time` | 5-00:00:00 |
| `--run_data_pipeline` | false |
| `--run_inference` | true |

### 5. Combine per-chunk metrics — `combine_af3_metrics.sh`

| | |
|---|---|
| **Input** | `structures/af3_results/chunk_*/metrics.tsv` |
| **Output** | `structures/metrics.tsv` |

### 6. Split by pTM quality — `split_by_quality.sh`

| | |
|---|---|
| **Input** | `structures/metrics.tsv` |
| **Output** | `structures/structures_results/HQ.tsv`, `MQ.tsv`, `LQ.tsv` |

| Parameter | Value |
|---|---|
| High quality (HQ) | pTM ≥ 0.70 |
| Medium quality (MQ) | 0.50 ≤ pTM < 0.70 |
| Low quality (LQ) | pTM < 0.50 |

### 7. Prepare Foldseek queries — `prepare_foldseek_queries.sh`

Symlinks every model's mmCIF into one query folder as `<family_id>.cif`.

| | |
|---|---|
| **Input** | `structures/metrics.tsv` |
| **Output** | `structures/queries/<family_id>.cif`, `structures/structures_results/ALL_pairs.tsv` |

### 8. Foldseek search — `run_foldseek_search.sh <db_path> <label>`

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

### 9. pTM by quality-class boxplot — `plot_ptm_quality_boxplot.R`

Re-derives the same HQ/MQ/LQ pTM tiers directly from `metrics.tsv` and plots each model's pTM as a jittered point per class, with a median marker and IQR error bar.

| | |
|---|---|
| **Input** | `structures/metrics.tsv` |
| **Output** | `structures/plots/pTM_by_quality_class_median.png` |

## Software

| Tool | Version |
|---|---|
| AlphaFold3 | 3.0.0 |
| jq | latest |
| Foldseek | latest |

R packages: `ggplot2`, `dplyr`.
