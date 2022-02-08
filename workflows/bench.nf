/*
========================================================================================
    LOCAL PARAMETER VALUES
========================================================================================
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/

// Check input path parameters to see if they exist
checkPathParamList = [ params.input, params.multiqc_config ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters (missing protocol or profile will exit the run.)
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

// Function to check if running offline
def isOffline() {
    try {
        return NXF_OFFLINE as Boolean
    }
    catch( Exception e ) {
        return false
    }
}

/*
========================================================================================
    CONFIG FILES
========================================================================================
*/

ch_multiqc_config        = file("$baseDir/assets/multiqc_config.yaml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()

/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/

//
// MODULE: Local to the pipeline
//             

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK                 } from '../subworkflows/local/input_check'
include { PREPARE_GENOME              } from '../subworkflows/local/prepare_genome'
include { PREPARE_REGIONS             } from '../subworkflows/local/prepare_regions'
include { PREPARE_TRUTH               } from '../subworkflows/local/prepare_truth'
include { PREPARE_BENCH               } from '../subworkflows/local/prepare_bench'
include { BENCHMARK_SHORT             } from '../subworkflows/local/benchmark_short'

/*
========================================================================================
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
========================================================================================
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { MULTIQC                     } from '../modules/nf-core/modules/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/modules/custom/dumpsoftwareversions/main'

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

// Info required for completion email and summary
def multiqc_report = []

workflow BENCH {

    ch_software_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate, and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    INPUT_CHECK.out.ch_sample
        .multiMap { it ->
            fasta_ch: [ it[0], it[2] ]
            type_ch:  [ it[0], it[1] ]
            bench_ch: [ it[0], it[3] ]
            truth_ch: [ it[0], it[4] ]
            bed_ch:   [ it[0], it[5] ]
            }
        .set { sample_ch }

    //
    // SUBWORKFLOW: Prepare bench file
    //
    PREPARE_BENCH (
        sample_ch.bench_ch
    )
    ch_bench = PREPARE_BENCH.out.ch_bench

    //
    // SUBWORKFLOW: Prepare truth file
    //
    PREPARE_TRUTH (
        sample_ch.truth_ch
    )
    ch_truth = PREPARE_TRUTH.out.ch_truth

    //
    // SUBWORKFLOW: Prepare genome files
    //
    PREPARE_GENOME (
        sample_ch.fasta_ch
    )
    ch_fasta = PREPARE_GENOME.out.ch_fasta_fai

    //
    // SUBWORKFLOW: Prepare high confidence regions
    //
    PREPARE_REGIONS (
        sample_ch.bed_ch
    )
    ch_bed = PREPARE_REGIONS.out.ch_bed_tbi

    //
    // SUBWORKFLOW: Benchamark short variants with hap.py
    ch_truth
        .join ( ch_bench, by: [0] )
        .join ( ch_fasta, by: [0] )
        .join ( ch_bed, by: [0] )
        .set { ch_sample }

    BENCHMARK_SHORT (
        ch_sample
    )
    ch_happy_summary = BENCHMARK_SHORT.out.ch_happy_summary

    //
    // MODULE: Pipeline reporting
    //

    //
    // MODULE: MultiQC
    //
    //workflow_summary    = WorkflowBench.paramsSummaryMultiqc(workflow, summary_params)
    //ch_workflow_summary = Channel.value(workflow_summary)

    //ch_multiqc_files = Channel.empty()
    //ch_multiqc_files = ch_multiqc_files.mix(Channel.from(ch_multiqc_config))
    //ch_multiqc_files = ch_multiqc_files.mix(ch_multiqc_custom_config.collect().ifEmpty([]))
    //ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    //ch_multiqc_files = ch_multiqc_files.mix(GET_SOFTWARE_VERSIONS.out.yaml.collect())
    //ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))

    //MULTIQC (
    //    ch_multiqc_files.collect()
    //)
    //multiqc_report       = MULTIQC.out.report.toList()
    //ch_software_versions = ch_software_versions.mix(MULTIQC.out.version.ifEmpty(null))
}

/*
========================================================================================
    COMPLETION EMAIL AND SUMMARY
========================================================================================
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
}

/*
========================================================================================
    THE END
========================================================================================
*/
