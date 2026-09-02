# Taxonomy

Classifies wastewater scaffolds with three complementary tools: Kraken2 (k-mer based, against RefSeq), MMseqs2 taxonomy (homology-based, against UniRef90), and geNomad (virus/plasmid identification). Each runs independently on the same scaffold chunks.

```
input_files/wastewater_scaffolds.tsv
   ↓
Split into ~60 Mbp chunks             (prepare_scaffolds.sh)
   ↓
Kraken2 classification (RefSeq)             (run_kraken2.sh)
MMseqs2 taxonomy (UniRef90)                 (run_mmseqs_taxonomy.sh)
geNomad virus/plasmid classification        (run_genomad.sh)
```

All scripts read a `PROJECT_DIR` environment variable pointing at your working directory:

```bash
export PROJECT_DIR=~/wastefams-run
scripts/prepare_scaffolds.sh
scripts/run_kraken2.sh
scripts/run_mmseqs_taxonomy.sh
scripts/run_genomad.sh
```

## Steps

### 1. Split scaffolds into chunks — `prepare_scaffolds.sh`

Converts all wastewater scaffolds to FASTA and splits them into ~60 Mbp chunks so the three classifiers below can run in parallel per chunk. No minimum-length filter is applied — short scaffolds are still worth classifying taxonomically.

| | |
|---|---|
| **Input** | `input_files/wastewater_scaffolds.tsv` |
| **Output** | `taxonomy/scaffold_chunks/scaffold_chunk_NNN.fasta` |

| Parameter | Value |
|---|---|
| Target chunk size | 60 Mbp |

### 2. Kraken2 classification — `run_kraken2.sh`

K-mer based taxonomic classification against a RefSeq database, reporting per-rank composition in MPA style and splitting scaffolds into classified/unclassified FASTAs.

| | |
|---|---|
| **Input** | `taxonomy/scaffold_chunks/*.fasta`, `resources/kraken2_refseq/` |
| **Output** | `taxonomy/kraken2/<chunk>.output.txt`, `<chunk>.report.txt`, `<chunk>.classified.fa`, `<chunk>.unclassified.fa` |

| Parameter | Value |
|---|---|
| `--threads` | 16 |
| `--use-names` | on |
| `--use-mpa-style` | on |
| Database | RefSeq |

### 3. MMseqs2 taxonomy — `run_mmseqs_taxonomy.sh`

Builds a query database from each chunk and assigns per-sequence taxonomy by homology search against UniRef90, exporting the result to a flat TSV.

| | |
|---|---|
| **Input** | `taxonomy/scaffold_chunks/*.fasta`, `resources/uniref90/uniref90DB` |
| **Output** | `taxonomy/mmseqs_taxonomy/<chunk>/taxonomyResult.tsv` |

### 4. geNomad classification — `run_genomad.sh`

Identifies viral and plasmid sequences among the scaffolds with geNomad's end-to-end pipeline (marker-based classification plus a neural-network score).

| | |
|---|---|
| **Input** | `taxonomy/scaffold_chunks/*.fasta`, `resources/genomad_db/` |
| **Output** | `taxonomy/genomad/<chunk>/` |

## Software

| Tool | Version |
|---|---|
| Kraken2 | latest |
| MMseqs2 | 18.8cc5c |
| geNomad | latest |
