/*
 * Prepare genome for benchmarking
 */

params.genome_options   = [:]

include { INDEX_REFERENCE  } from '../../modules/local/index_reference'       addParams( options: params.genome_options )

workflow PREPARE_GENOME {
    take:
    ch_fasta

    main:
    /*
     * Make chromosome sizes file
     */
    INDEX_REFERENCE ( ch_fasta )
    ch_fasta_fai = INDEX_REFERENCE.out.fai
    samtools_version = INDEX_REFERENCE.out.versions

    emit:
    ch_fasta_fai
    samtools_version
}