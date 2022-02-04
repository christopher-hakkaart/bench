#!/usr/bin/env nextflow
/*
========================================================================================
    nf-core/bench
========================================================================================
    Github : https://github.com/nf-core/bench
    Website: https://nf-co.re/bench
    Slack  : https://nfcore.slack.com/channels/bench
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
========================================================================================
    GENOME PARAMETER VALUES
========================================================================================
*/

params.fasta = WorkflowMain.getGenomeAttribute(params, 'fasta')

/*
========================================================================================
    VALIDATE & PRINT PARAMETER SUMMARY
========================================================================================
*/

WorkflowMain.initialise(workflow, params, log)

/*
========================================================================================
    NAMED WORKFLOW FOR PIPELINE
========================================================================================
*/

include { BENCH } from './workflows/bench'

//
// WORKFLOW: Run main nf-core/bench analysis pipeline
//
workflow NFCORE_BENCH {
    BENCH ()
}

/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/

//
// WORKFLOW: Execute a single named workflow for the pipeline
//
workflow {
    NFCORE_BENCH ()
}

/*
========================================================================================
    THE END
========================================================================================
*/
