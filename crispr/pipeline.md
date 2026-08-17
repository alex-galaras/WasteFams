# CRISPR Elements

Detects CRISPR-Cas systems in wastewater scaffolds with CCTyper, then links the resulting CRISPR arrays and Cas operons to the protein families that overlap them.

```
Scaffold chunks (nucleotide FASTA)
   ↓
CCTyper                       (run_cctyper.sh)
   ↓
Merge per-chunk CCTyper output (merge_cctyper_results.sh)
   ↓
Metrics                       (report_crispr_metrics.sh)
   ↓
Intersect with protein families (intersect_with_families.sh)
   ↓
Top families / operons        (report_top_families.sh)
```

All scripts read a `PROJECT_DIR` environment variable pointing at your working directory:

```bash
export PROJECT_DIR=~/wastefams-run
scripts/run_cctyper.sh
scripts/merge_cctyper_results.sh
scripts/report_crispr_metrics.sh
scripts/intersect_with_families.sh
scripts/report_top_families.sh
```

## Steps

### 1. CRISPR-Cas typing — `run_cctyper.sh`

CCTyper is run directly on scaffold sequences (it calls genes itself via Prodigal in metagenome mode) and both detects CRISPR arrays and types any Cas operons present.

`taxonomy/scaffold_chunks/*.fasta` is produced by a taxonomic-assignment pipeline that isn't part of this repository — supply your own scaffold FASTA chunks at that path.

| | |
|---|---|
| **Input** | `taxonomy/scaffold_chunks/*.fasta` |
| **Output** | `crispr_elements/cctyper_output/<chunk>/` |

| Parameter | Value |
|---|---|
| CCTyper `-t` (threads) | 24 |
| CCTyper `--prodigal` | meta |

### 2. Merge per-chunk results — `merge_cctyper_results.sh`

| | |
|---|---|
| **Input** | `crispr_elements/cctyper_output/*/crisprs_all.tab`, `.../cas_operons.tab` |
| **Output** | `crispr_elements/crisprs_all_results.tab`, `crispr_elements/cas9_operons_results.tab` |

### 3. Metrics — `report_crispr_metrics.sh`

Reports the number of CRISPR arrays and predicted Cas operons, and how many distinct scaffolds carry each.

| | |
|---|---|
| **Input** | `crispr_elements/crisprs_all_results.tab`, `crispr_elements/cas9_operons_results.tab` |
| **Output** | printed to stdout |

### 4. Intersect with protein families — `intersect_with_families.sh`

Converts CRISPR arrays, Cas operons, and protein-family gene coordinates to BED (correcting Prodigal/CCTyper's 1-based coordinates to BED's 0-based start), then intersects each against the family coordinates to find which families overlap a CRISPR array or Cas operon.

`members_link_prodigal/WWF_IMG_prodigal.tsv` (protein family members linked to their Prodigal ORF coordinates) is produced by a separate linking step that isn't part of this repository.

| | |
|---|---|
| **Input** | `members_link_prodigal/WWF_IMG_prodigal.tsv`, `crispr_elements/crisprs_all_results.tab`, `crispr_elements/cas9_operons_results.tab` |
| **Output** | `crispr_elements/CRISPR_WWF_intersect.tab`, `crispr_elements/CAS_WWF_intersect.tab` |

### 5. Top families / operons — `report_top_families.sh`

Reports the protein families most often found in Cas operons, and the Cas operons that overlap the most distinct families.

| | |
|---|---|
| **Input** | `crispr_elements/CAS_WWF_intersect.tab` |
| **Output** | printed to stdout |

## Software

| Tool | Version |
|---|---|
| CCTyper | latest |
| bedtools | latest |
