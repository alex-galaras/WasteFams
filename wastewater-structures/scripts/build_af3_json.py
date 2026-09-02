#!/usr/bin/env python3
# Convert each per-family FASTA into an AlphaFold3 input JSON. The
# representative (first) sequence, ungapped, is used as the query sequence;
# the family's own trimmed alignment (the whole FASTA file, gaps included)
# is passed as a precomputed "unpairedMsa" so AlphaFold3's own genetic-search
# MSA pipeline can be skipped at inference time (--run_data_pipeline=false
# in Step 4).
#
# Usage: build_af3_json.py <PROJECT_DIR>
import json
import sys
from pathlib import Path


def read_first_ungapped_sequence(fasta_path: Path) -> str:
    """Read the first sequence (ungapped) from a FASTA/MSA file."""
    seq_lines = []
    in_first = False
    with fasta_path.open("r", encoding="utf-8") as fh:
        for line in fh:
            if not line.strip():
                continue
            if line.startswith(">"):
                if in_first:
                    break  # stop after first sequence
                in_first = True
                continue
            if in_first:
                seq_lines.append(line.strip())
    return "".join(seq_lines).replace("-", "")


def read_msa_text(fasta_path: Path) -> str:
    """Return the entire FASTA/MSA file contents as a string."""
    text = fasta_path.read_text(encoding="utf-8")
    if not text.endswith("\n"):
        text += "\n"
    return text


def fasta_to_json_obj(fasta_path: Path) -> dict:
    """Convert a FASTA/MSA file into the desired JSON structure."""
    name = fasta_path.stem
    sequence = read_first_ungapped_sequence(fasta_path)
    unpaired_msa = read_msa_text(fasta_path)

    return {
        "name": name,
        "sequences": [
            {
                "protein": {
                    "id": ["A"],
                    "sequence": sequence,
                    "unpairedMsa": unpaired_msa,
                    "pairedMsa": [],
                    "templates": []
                }
            }
        ],
        "dialect": "alphafold3",
        "version": 1,
        "modelSeeds": [1]
    }


def main():
    project_dir = Path(sys.argv[1])
    fasta_dir = project_dir / "structures" / "fasta_for_structures"
    json_dir = project_dir / "structures" / "json_files"
    json_dir.mkdir(parents=True, exist_ok=True)

    fasta_exts = {".fa", ".fasta", ".faa"}

    count = 0
    for fasta_file in sorted(fasta_dir.iterdir()):
        if fasta_file.suffix.lower() not in fasta_exts:
            continue

        json_obj = fasta_to_json_obj(fasta_file)
        out_path = json_dir / f"{fasta_file.stem}.json"

        with out_path.open("w", encoding="utf-8") as out_fh:
            json.dump(json_obj, out_fh, indent=2, ensure_ascii=False)

        count += 1

    print(f"Wrote {count} JSON file(s) to {json_dir}")


if __name__ == "__main__":
    main()
