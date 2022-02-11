//
// Prepare tuth set
//

params.options = [:]
params.genome_options = [:]

include { REMOVE_CHR  } from '../../modules/local/remove_chr'                       addParams( options: params.options )
include { TABIX_BGZIP } from '../../modules/nf-core/modules/tabix/bgzip/main'       addParams( options: params.genome_options )


workflow PREPARE_TRUTH {
    take:
    truth_ch //

    main:
    /*
     * Rename using meta
     */
    truth_ch.map{ meta, truth ->
        new_meta = meta.clone()
        new_meta.id = truth.simpleName
        new_meta.workflow = meta.id
        [new_meta, truth]
        }.set{truth_renamed}

    /*
     * Remove chr prefix from chromosomes
     */
    REMOVE_CHR (
        truth_renamed
    )
    truth_nochr = REMOVE_CHR.out.vcf

    /*
     * BGZIP truth file
     */
    TABIX_BGZIP (
        truth_nochr
    )
    truth_gz = TABIX_BGZIP.out.gz
    
    /*
     * Revert rename using meta
     */
    truth_gz.map{ meta, truth ->
        new_meta = [:]
        new_meta.id = meta.workflow
        [new_meta, truth]
        }.set{ch_truth}

    emit:
    ch_truth
}