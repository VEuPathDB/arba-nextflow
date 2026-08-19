# arba-nextflow

Nextflow pipeline that generates ARBA (Association-Rule-Based Annotator) protein annotations from InterProScan results.

## Overview

VEuPathDB uses UniProt's ARBA rule system to automatically assign product names and Pfam-based descriptions to predicted proteins based on their InterPro domain matches and taxonomic lineage. Given a set of InterProScan results and an NCBI taxon ID for the organism, this pipeline determines the organism's taxonomic lineage, applies the ARBA rulesheet to select the best-matching annotation rules for each protein, and produces a final annotation table (with supporting Pfam descriptions) that is loaded into VEuPathDB genomic databases as part of the standard annotation build.

## Requirements

- [Nextflow](https://www.nextflow.io/) (DSL2)
- [Docker](https://www.docker.com/) — the pipeline runs each step in the `veupathdb/edirect` and `veupathdb/arba` containers; `docker { enabled = true }` is set in `nextflow.config`

## Usage

```
nextflow run VEuPathDB/arba-nextflow -r main \
  --interproResults /path/to/interproscan_results.tsv \
  --taxonId 7159 \
  --abbrev aaegLVP_AGWG \
  --outputDir /path/to/output \
  -resume -C my.config
```

The pipeline has a single, unnamed entry point (`workflow { ... }` in `main.nf`), so no `-entry` flag is needed.

Steps performed:
1. `runEDirect` — queries NCBI Taxonomy via EDirect (`efetch`/`xtract`) for the taxon's lineage and writes it, root-to-leaf, to `lineage.txt`.
2. `assignArbaAnnotation` — runs `assignArbaNames.pl`, matching InterProScan domain hits against the ARBA rulesheet, using the taxonomic lineage to pick the most specific applicable rule, and producing `names.tsv`.
3. `formatArbaOutput` — runs `formatArbaOutput.pl` to normalize the assigned names into `arbaAnnotation.tsv`.
4. `pfam` — runs `addPfamDescriptions.pl` to attach Pfam descriptions from the InterProScan results, producing `pfam.tsv`.
5. `formatPFamAndArba` — runs `formatAnnotationOutput.pl` to merge the ARBA names and Pfam descriptions into the final `arbaAndPfamResults.tsv`, published to `params.outputDir`.

## Key Parameters

| Parameter | Description | Default |
|---|---|---|
| `params.interproResults` | Path to the InterProScan results TSV for the organism | `data/iprscan/aaegLVP_AGWG.tsv` |
| `params.taxonId` | NCBI taxonomy ID of the organism | `7159` |
| `params.abbrev` | VEuPathDB organism abbreviation, carried through to the output | `aaegLVP_AGWG` |
| `params.rulesheet` | Path to the ARBA rulesheet (taxon/UniRule mappings) | `bin/rulesheet.tsv` |
| `params.outputDir` | Directory the final annotation file is published to | `output` (relative to launch directory) |

## Output

A single tab-separated file, `arbaAndPfamResults.tsv`, published to `params.outputDir`, containing per-protein ARBA-assigned names merged with Pfam domain descriptions.
