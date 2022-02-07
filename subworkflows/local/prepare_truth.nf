//
// Prepare tuth set
//

params.options = [:]

include { REMOVE_CHR  } from '../../modules/local/remove_chr'        addParams( options: params.options )
include { TABIX_BGZIP } from '../../modules/local/tabix_bgzip'       addParams( options: params.options )

workflow PREPARE_TRUTH {
    take:
    truth_ch // meta and path

    main:
    REMOVE_CHR (
        truth_ch
    )

    TABIX_BGZIP (
        REMOVE_CHR.out.vcf
    )
    ch_truth = TABIX_BGZIP.out.gz

    emit:
    ch_truth
}