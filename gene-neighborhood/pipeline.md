# Gene Neighborhood

Annotates the genes surrounding each protein family member (its gene neighborhood) with Pfam domains, via DIAMOND search against the Pfam sequence database (pfamseq).

```
resources/pfam_database/pfamseq
   ↓
Build Pfam DIAMOND database    (build_pfam_diamond_db.sh)
   ↓
input_files/fasta_chunks/*.fasta
   ↓
DIAMOND search + best-hit      (run_diamond_search.sh)
```

All scripts read a `PROJECT_DIR` environment variable pointing at your working directory:

```bash
export PROJECT_DIR=~/wastefams-run
scripts/build_pfam_diamond_db.sh
scripts/run_diamond_search.sh
```

## Steps

### 1. Build the Pfam DIAMOND database — `build_pfam_diamond_db.sh`

| | |
|---|---|
| **Input** | `resources/pfam_database/pfamseq` |
| **Output** | `resources/pfam_database/pfamdb.dmnd` |

### 2. DIAMOND search — `run_diamond_search.sh`

Maps each Pfam sequence id to its gene name (from the `GN=` field in the pfamseq header), then searches every gene-neighborhood FASTA chunk against the Pfam DIAMOND database, keeping only the best (highest-ranked) hit per query.

| | |
|---|---|
| **Input** | `input_files/fasta_chunks/*.fasta`, `resources/pfam_database/pfamdb.dmnd`, `resources/pfam_database/pfamseq` |
| **Output** | `gene_neighborhood/pfam_id2gene.tsv`, `gene_neighborhood/<chunk>.besthit.tsv` (per chunk) |

| Parameter | Value |
|---|---|
| `--evalue` | 1e-5 |
| `--max-target-seqs` | 10 |
| `--threads` | 24 |
| Hits kept per query | best (first-listed) |

## Software

| Tool | Version |
|---|---|
| DIAMOND | latest |
| Pfam (pfamseq) | latest |
