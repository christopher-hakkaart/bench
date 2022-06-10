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
include { MULTIQC                      } from '../modules/local/multiqc' // Version 1.10.1 fails because of python version
//include { MERGE_RESULTS                } from '../modules/local/merge_results' // Version 1.10.1 fails because of python version

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK                  } from '../subworkflows/local/input_check'
include { PREPARE_GENOME               } from '../subworkflows/local/prepare_genome'
include { PREPARE_REGIONS              } from '../subworkflows/local/prepare_regions'
include { PREPARE_VCF as PREPARE_TRUTH } from '../subworkflows/local/prepare_vcf'
include { PREPARE_VCF as PREPARE_BENCH } from '../subworkflows/local/prepare_vcf'
include { BENCHMARK_SHORT              } from '../subworkflows/local/benchmark_short'
include { BENCHMARK_SV                 } from '../subworkflows/local/benchmark_sv'

/*
========================================================================================
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
========================================================================================
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS  } from '../modules/nf-core/modules/custom/dumpsoftwareversions/main'

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

// Info required for completion email and summary
def multiqc_report = []

workflow BENCH {

    println(params.genome)

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
            bench_ch: [ it[0], it[3] ]
            truth_ch: [ it[0], it[4] ]
            bed_ch:   [ it[0], it[5] ]
            }
        .set { sample_ch }

    //ONLY FOR GRCH37 PREPARE BENCH AND VCF FILES NEEDED
    if (params.genome == 'GRCh37') {
        //
        // SUBWORKFLOW: Prepare bench file
        //
        PREPARE_BENCH(
            sample_ch.bench_ch
        )
        ch_bench = PREPARE_BENCH.out.ch_vcf
        ch_software_versions = ch_software_versions.mix(PREPARE_BENCH.out.bgzip_version.first().ifEmpty(null))
        ch_software_versions = ch_software_versions.mix(PREPARE_BENCH.out.bcftools_version.first().ifEmpty(null))
        ch_software_versions = ch_software_versions.mix(PREPARE_BENCH.out.tabix_version.first().ifEmpty(null))

        //
        // SUBWORKFLOW: Prepare truth file
        //
        PREPARE_TRUTH(
            sample_ch.truth_ch
        )
        ch_truth = PREPARE_TRUTH.out.ch_vcf
        ch_software_versions = ch_software_versions.mix(PREPARE_TRUTH.out.bgzip_version.first().ifEmpty(null))
        ch_software_versions = ch_software_versions.mix(PREPARE_TRUTH.out.bcftools_version.first().ifEmpty(null))
        ch_software_versions = ch_software_versions.mix(PREPARE_TRUTH.out.tabix_version.first().ifEmpty(null))
    } else {
        ch_bench = sample_ch.bench_ch
        ch_truth = sample_ch.truth_ch
    }

    //
    // SUBWORKFLOW: Prepare genome files
    //
    PREPARE_GENOME (
        sample_ch.fasta_ch
    )
    ch_fasta = PREPARE_GENOME.out.ch_fasta_fai
    ch_software_versions = ch_software_versions.mix(PREPARE_GENOME.out.samtools_version.first().ifEmpty(null))

    //
    // SUBWORKFLOW: Prepare high confidence regions
    //
    PREPARE_REGIONS (
        sample_ch.bed_ch
    )
    ch_bed = PREPARE_REGIONS.out.ch_bed
    ch_software_versions = ch_software_versions.mix(PREPARE_REGIONS.out.bgzip_version.first().ifEmpty(null))
    ch_software_versions = ch_software_versions.mix(PREPARE_REGIONS.out.tabix_version.first().ifEmpty(null))

    //
    // Prepare sample channles
    //
    ch_bench
        .join ( ch_truth, by: [0] )
        .join ( ch_fasta, by: [0] )
        .join ( ch_bed, by: [0] )
        .branch { it ->
            short_ch: it[0].variant_type == 'SHORT'
            sv_ch:    it[0].variant_type == 'STRUCTURAL'
            }
        .set{ch_sample_type}

    //
    // SUBWORKFLOW: Benchmark short variants with hap.py
    //
    BENCHMARK_SHORT (
        ch_sample_type.short_ch
    )
    ch_happy_summary     = BENCHMARK_SHORT.out.ch_happy_summary
    ch_software_versions = ch_software_versions.mix(BENCHMARK_SHORT.out.happy_version.first().ifEmpty(null))
    ch_software_versions = ch_software_versions.mix(BENCHMARK_SHORT.out.short_plot_version.first().ifEmpty(null))

    //
    // SUBWORKFLOW: Benchamark sv variants with truvari
    //
    BENCHMARK_SV (
        ch_sample_type.sv_ch
    )
    ch_truvari_summary    = BENCHMARK_SV.out.ch_truvari_summary
    ch_truvari_table_size = BENCHMARK_SV.out.ch_truvari_table_size
    ch_truvari_table_type = BENCHMARK_SV.out.ch_truvari_table_type
    ch_truvari_table_sv   = BENCHMARK_SV.out.ch_truvari_table_sv
    ch_truvari_svg        = BENCHMARK_SV.out.ch_truvari_svg
    ch_software_versions  = ch_software_versions.mix(BENCHMARK_SV.out.truvari_version.first().ifEmpty(null))
    ch_software_versions  = ch_software_versions.mix(BENCHMARK_SV.out.sv_plot_version.first().ifEmpty(null))

    //
    // SUBWORKFLOW: Merge results
    //
    //ch_truvari_table_type
    //    .map{ it -> it[1] }
    //    .collect()
    //    .set{ch_test}

    //MERGE_RESULTS (
    //    ch_test
    //)
    //ch_merged_csv = MERGE_RESULTS.out.merged_csv

    /*
    * MODULE: Parse software version numbers
    */
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_software_versions.unique().collectFile()
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowBench.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(Channel.from(ch_multiqc_config))
    ch_multiqc_files = ch_multiqc_files.mix(ch_multiqc_custom_config.collect().ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())

    MULTIQC (
        ch_multiqc_files.collect()
    )
    multiqc_report       = MULTIQC.out.report.toList()
    ch_software_versions = ch_software_versions.mix(MULTIQC.out.version.ifEmpty(null))
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
