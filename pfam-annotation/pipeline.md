# Pfam Annotation

Annotates protein family representatives with Pfam domains via HMMER, maps those domains to GO terms (biological process / molecular function / cellular component), and links the annotation back to individual family members and their biome metadata.

```
step5_hhfilter/hhfilter_members.tsv (families passing HHfilter)
   ↓
Build Pfam-search input               (build_pfam_input.sh)
   ↓
HMMER search vs Pfam-A                (run_pfam_search.sh)
   ↓
Process hits + Pfam descriptions      (process_pfam_hits.sh)
   ↓
GO terms + link back to members       (add_go_terms.sh)
```

All scripts read a `PROJECT_DIR` environment variable pointing at your working directory:

```bash
export PROJECT_DIR=~/wastefams-run
scripts/build_pfam_input.sh
scripts/run_pfam_search.sh
scripts/process_pfam_hits.sh
scripts/add_go_terms.sh
```

## Steps

### 1. Build Pfam-search input — `build_pfam_input.sh`

Takes the representative sequence of every family that passed HHfilter (Step 6 of protein-family-generation) and assembles them into one table.

| | |
|---|---|
| **Input** | `step3_protein_families/families_100.tsv`, `step2_deduplication_summary/total_sequences.tsv`, `step5_hhfilter/hhfilter_members.tsv` |
| **Output** | `analysisII_pfam/input_pfam.tsv` |

### 2. HMMER search against Pfam-A — `run_pfam_search.sh`

Searches all representative sequences against Pfam-A with `hmmsearch`.

| | |
|---|---|
| **Input** | `analysisII_pfam/input_pfam.tsv`, `resources/pfam_database/Pfam-A.hmm` |
| **Output** | `analysisII_pfam/pfam_results.tsv` |

| Parameter | Value |
|---|---|
| `-T` (per-sequence bit score) | 25 |
| `--domT` (per-domain bit score) | 22 |
| `--incT` (inclusion threshold, sequences) | 7 |
| `--incdomT` (inclusion threshold, domains) | 5 |
| `--cpu` | 20 |

### 3. Process Pfam hits — `process_pfam_hits.sh`

Joins families to their Pfam hits, strips the trailing Pfam version digits (e.g. `PF00001.21` → `PF00001`), and attaches each Pfam's description.

| | |
|---|---|
| **Input** | `analysisII_pfam/input_pfam.tsv`, `analysisII_pfam/pfam_results.tsv`, `resources/pfam_database/table_pfam_description` |
| **Output** | `analysisII_pfam/fam_rep_pfam_description.tsv` |

### 4. GO terms + link back to family members — `add_go_terms.sh`

Maps each family's Pfam domain to a GO id via `pfam2go`, resolves that id to its biological process (BP), molecular function (MF), and cellular component (CC) name, then joins the Pfam description and MF term back to each family's biome metadata so the annotation is available at the individual-member level.

`analysisI_biome/wastewater_ecotype_distribution.tsv` is a family → biome lookup table (family id, biome, member count, family size, percent) that is **not** the same file `biome-distribution/` produces (`families_ecosystems.cleaned.tsv`, a different, wider table) — it comes from an earlier/separate biome-summary step not included in this repository. It's provided in this repository at `data/wastewater_ecotype_distribution.tsv`; copy or symlink it to `analysisI_biome/wastewater_ecotype_distribution.tsv` under your `PROJECT_DIR`.

| | |
|---|---|
| **Input** | `analysisII_pfam/fam_rep_pfam_description.tsv`, `resources/pfam_database/pfam_go_tables/pfam2go_GOid.tsv`, `resources/pfam_database/pfam_go_tables/{biological_process,molecular_function,cellular_component}_go_to_name.tsv`, `analysisI_biome/wastewater_ecotype_distribution.tsv` |
| **Output** | `analysisII_pfam/wastewater_fam_BP.tsv`, `wastewater_fam_MF.tsv`, `wastewater_fam_CC.tsv`, `fam_biome_Description.tsv`, `fam_biome_MF.tsv` |

## Software

| Tool | Version |
|---|---|
| HMMER | 3.3.2 |
| Pfam-A | v.37 |
