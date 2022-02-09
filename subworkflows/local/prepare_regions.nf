//
// Get benchset files
//

params.options = [:]

include { TABIX_BGZIP } from '../../modules/local/tabix_bgzip' addParams( options: params.options )
include { TABIX_TABIX } from '../../modules/local/tabix_tabix' addParams( options: params.options )

workflow PREPARE_REGIONS {
    take:
    ch_bed // meta and path

    main:
    /*
     * Compress bed
     */
    TABIX_BGZIP (
        ch_bed
    )
    /*
     * Index compressed bed
     */
    TABIX_TABIX (
        TABIX_BGZIP.out.gz
    )
    ch_bed_tbi = TABIX_TABIX.out.gz_tbi

    emit:
    ch_bed_tbi
    
}
