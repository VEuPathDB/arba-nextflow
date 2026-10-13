#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process runEDirect {
  container 'veupathdb/edirect:1.0.0'
  input:
    path filteredInterproResults
    val abbrev
    val taxon_id

  output:
    path 'lineage.txt', emit: lineage
    path filteredInterproResults, emit: interpro
    tuple val(abbrev), val(taxon_id), emit: organism

  script:
    """
    efetch -db taxonomy -id $taxon_id -format xml \
    | xtract -pattern Taxon -block LineageEx -sep "\n" -element TaxId > taxonIds.txt
    # Adds our input id to the file, as it is not
    echo "$taxon_id" >> taxonIds.txt
    tac taxonIds.txt > lineage.txt
    """
}

process assignArbaAnnotation {
  container 'veupathdb/arba:1.6.0'
  input:
    path lineage
    path filteredInterproResults
    tuple val(abbrev), val(taxon_id)
    path rulesheet

  output:
    path 'names.tsv', emit: names
    path filteredInterproResults, emit: interpro
    tuple val(abbrev), val(taxon_id), emit: organism

  script:
    """
    assignArbaNames.pl --iprscan $filteredInterproResults \
                       --arbaRules $rulesheet \
                       --lineage $lineage \
                       --outputFile names.tsv
    """
}

process formatArbaOutput {
  container 'veupathdb/arba:1.6.0'
  input:
    path arbaNames
    path filteredInterproResults
    tuple val(abbrev), val(taxon_id)

  output:
    path 'arbaAnnotation.tsv', emit: annotation
    path filteredInterproResults, emit: interpro
    tuple val(abbrev), val(taxon_id), emit: organism

  script:
    """
    formatArbaOutput.pl --arbaOutput $arbaNames --outputFile arbaAnnotation.tsv
    """
}

process pfam {
  container 'veupathdb/arba:1.6.0'
  input:
    path arbaAnnotations
    path filteredInterproResults
    tuple val(abbrev), val(taxon_id)

  output:
    path 'pfam.tsv', emit: pfam
    path arbaAnnotations, emit: annotation
    tuple val(abbrev), val(taxon_id), emit: organism

  script:
    """
    addPfamDescriptions.pl --iprscan $filteredInterproResults \
                           --arbaOutput $arbaAnnotations \
                           --outputFile pfam.tsv
    """
}

process formatPFamAndArba {
  container 'veupathdb/arba:1.6.0'

  publishDir "$params.outputDir", mode: "copy"

  input:
    path pfam
    path arbaAnnotations
    tuple val(abbrev), val(taxon_id)

  output:
    path 'arbaAndPfamResults.tsv'

  script:
    """
    formatAnnotationOutput.pl --arba $arbaAnnotations \
                              --pfam $pfam \
                              --output arbaAndPfamResults.tsv
    """
}

workflow arbaAssign {
  take:
      interproResults
      taxonId
      abbrev

  main:
      runEDirect(interproResults, abbrev, taxonId)
      assignArbaAnnotation(runEDirect.out.lineage, runEDirect.out.interpro, runEDirect.out.organism, params.rulesheet)
      formatArbaOutput(assignArbaAnnotation.out.names, assignArbaAnnotation.out.interpro, assignArbaAnnotation.out.organism)
      pfam(formatArbaOutput.out.annotation, formatArbaOutput.out.interpro, formatArbaOutput.out.organism)
      formatPFamAndArba(pfam.out.pfam, pfam.out.annotation, pfam.out.organism)

}
