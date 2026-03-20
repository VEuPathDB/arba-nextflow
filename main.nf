#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//---------------------------------------------------------------
// Includes
//---------------------------------------------------------------

include { arbaAssign } from './modules/arbaAssign.nf'

//---------------------------------------------------------------
// arba
//---------------------------------------------------------------

workflow {

    if (!params.interproResults) {
        throw new Exception("Missing params.interproResults")
    }
    if (!params.proteomes) {
        throw new Exception("Missing params.proteomes")
    }
    if (!params.taxonIdFile) {
        throw new Exception("Missing params.taxonIdFile")
    }

    abbrevAndIds = Channel
        .fromPath(params.taxonIdFile)
        .splitCsv(sep: '\t', header: false)
        .map { row ->

            // ----------------------------
            // Validate row structure
            // ----------------------------
            if (row.size() != 2) {
                error "Invalid row in ${params.taxonIdFile}: ${row}"
            }

            def (abbrev, id) = row

            // ----------------------------
            // Clean and validate ID
            // ----------------------------
            def cleanId = id?.trim()
            if (!cleanId?.isLong()) {
                error "Invalid taxon ID '${id}' for abbrev '${abbrev}'"
            }

            tuple(abbrev, cleanId.toLong())
        }

    arbaAssign(abbrevAndIds)
}
