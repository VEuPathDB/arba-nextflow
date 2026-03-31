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
    if (!params.proteome) {
        throw new Exception("Missing params.proteomes")
    }
    if (!params.taxonId) {
        throw new Exception("Missing params.taxonIdFile")
    }
    arbaAssign(params.interproResults,params.proteome,params.taxonId,params.abbrev)
}
