#!/usr/bin/env python3
import re
import sys
import argparse


def is_uninformative_name(description):
    """
    Check if the description contains uninformative terms.
    Enhanced to catch database identifiers and other uninformative patterns.
    """
    if not description or not description.strip():
        return True

    description_str = description.strip()
    description_lower = description_str.lower()

    # 1. CLASSIC UNINFORMATIVE TERMS
    classic_uninformative_terms = [
        "hypothetical protein",
        "hypothetical_protein",
        "unspecified product",
        "conserved hypothetical protein",
        "predicted protein",
        "protein of unknown function",
        "uncharacterized protein",
        "conserved protein, unknown function",
        "---NA---",
        "contig",
    ]

    for term in classic_uninformative_terms:
        if term in description_lower:
            return True

    if description_lower.startswith("has domain(s) with predicted"):
        desc_split = description_lower.split(",")
        length = len(desc_split)
        if " and " in description_lower:
            length += 1
        if length > 1:
            return True

    # 2. DATABASE IDENTIFIERS (single word patterns)
    if " " not in description_str and description_str.startswith("XM"):
        return True

    # 3. CAD IDENTIFIERS (CADXXXXXX.X pattern)
    if re.match(r"^CAD\d+(\.\d+)?$", description_str):
        return True

    # 4. CONSERVED [SPECIES] PROTEIN, UNKNOWN FUNCTION
    if re.search(r"conserved\s+\w+\s+protein,?\s*unknown\s+function", description_lower):
        return True

    # 5. UNCHARACTERIZED LOC PATTERNS
    if re.search(r"uncharacterized\s+loc\d+", description_lower):
        return True

    # 6. ORTHOLOG PATTERNS
    if description_lower.startswith("ortholog of "):
        return True

    # 7. CSON/BGH/DEHA IDENTIFIERS
    if (
        description_str.startswith("CSON")
        or description_str.startswith("hypothetical protein BGH")
        or description_str.startswith("DEHA2A")
    ):
        return True

    # 8. ADDITIONAL DATABASE IDENTIFIER PATTERNS (single words)
    if " " not in description_str:
        db_id_patterns = [
            r"^[A-Z]{2,4}\d+$",
            r"^[A-Z]{3,5}_\d+$",
            r"^LOC\d+$",
            r"^[A-Z]+\d+\.[0-9]+$",
        ]
        for pattern in db_id_patterns:
            if re.match(pattern, description_str):
                return True

    # 9. GENERIC SINGLE-TERM DESCRIPTIONS
    generic_terms = ["protein", "gene product", "gene", "orf"]
    if description_lower in generic_terms:
        return True

    # 10. "Similar to [Source:...]" pattern
    if description_str.startswith("Similar to ["):
        return True

    return False


def filter_arba(input_file, output_file):
    """
    Filter arbaAnnotation.tsv, removing lines whose product description is uninformative.

    Input format (tab-separated, no header):
        gene_id  description  source_type  arba_id(s)

    Output: same format, uninformative lines removed.
    """
    kept = 0
    removed = 0

    with open(input_file) as fh, open(output_file, "w") as out:
        for line in fh:
            line = line.rstrip("\n")
            if not line.strip():
                continue
            parts = line.split("\t")
            if len(parts) < 2:
                continue
            description = parts[1]
            if is_uninformative_name(description):
                removed += 1
            else:
                out.write(line + "\n")
                kept += 1

    print(f"ARBA: kept {kept}, removed {removed} uninformative lines → {output_file}")


def filter_pfam(input_file, output_file):
    """
    Filter pfam.tsv at the individual domain level.

    Input format (tab-separated, no header):
        gene_id  pf_ids(comma-sep)  descriptions(comma-sep)

    PF IDs never contain commas, so the count of PF IDs determines how many
    descriptions there are. Descriptions are split using split(",", n-1) so that
    descriptions containing commas (e.g. "WD domain, G-beta repeat") are kept
    intact as a single entry paired with their PF ID.

    Each (PF ID, description) pair is filtered independently. Lines where all
    pairs are uninformative are dropped; lines with at least one informative pair
    are written with only the informative pairs retained.
    """
    kept = 0
    removed = 0

    with open(input_file) as fh, open(output_file, "w") as out:
        for line in fh:
            line = line.rstrip("\n")
            if not line.strip():
                continue
            parts = line.split("\t")
            if len(parts) < 3:
                continue

            gene_id = parts[0]
            pf_ids = parts[1].split(",")
            descriptions = parts[2].split(";;")

            informative_ids = []
            informative_descs = []
            for pf_id, desc in zip(pf_ids, descriptions):
                if not is_uninformative_name(desc):
                    informative_ids.append(pf_id)
                    informative_descs.append(desc)

            if not informative_ids:
                removed += 1
            else:
                filtered_line = "\t".join([
                    gene_id,
                    ",".join(informative_ids),
                    ";;".join(informative_descs),
                ])
                out.write(filtered_line + "\n")
                kept += 1

    print(f"Pfam: kept {kept}, removed {removed} uninformative lines → {output_file}")


def parse_args():
    parser = argparse.ArgumentParser(
        description="Filter uninformative product descriptions from ARBA or Pfam annotation files."
    )
    parser.add_argument(
        "--type",
        choices=["arba", "pfam"],
        required=True,
        help="File type to filter: 'arba' (arbaAnnotation.tsv) or 'pfam' (pfam.tsv).",
    )
    parser.add_argument(
        "--input",
        required=True,
        help="Path to the input TSV file.",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Path to the filtered output TSV file.",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    if args.type == "arba":
        filter_arba(args.input, args.output)
    elif args.type == "pfam":
        filter_pfam(args.input, args.output)
    else:
        print(f"Unknown type: {args.type}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
