//
// Prepare tuth set
//

params.options = [:]
params.genome_options = [:]

include { REMOVE_CHR  } from '../../modules/local/remove_chr'                       addParams( options: params.options )
include { TABIX_BGZIP } from '../../modules/nf-core/modules/tabix/bgzip/main'       addParams( options: params.genome_options )
include { TABIX_TABIX } from '../../modules/nf-core/modules/tabix/tabix/main'       addParams( options: params.genome_options )


workflow PREPARE_TRUTH {
    take:
    truth_ch //

    main:
    /*
     * Rename using meta
     */
    truth_ch.map{ meta, truth ->
        new_meta = meta.clone()
        new_meta.id = meta.truth_set
        [new_meta, truth]
        }
    .set{truth_renamed}

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
     * TABIX truth file
     */
    TABIX_TABIX (
        truth_gz
    )
    truth_tbi = TABIX_TABIX.out.tbi

    /*
     * Revert rename using meta
     */
    truth_gz
        .join(truth_tbi, by: [0] )
        .set { truth_gz_tbi }
    

    truth_gz_tbi.map{ meta, gz, tbi ->
        new_meta = meta.clone()
        new_meta.id = meta.workflow
        [new_meta, gz, tbi]
        }
    .set{ch_truth}

    emit:
    ch_truth
}