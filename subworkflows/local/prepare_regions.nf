//
// Get benchset files
//

params.options = [:]

include { TABIX_BGZIPTABIX } from '../../modules/local/tabix_bgziptabix' addParams( options: params.options )

workflow PREPARE_REGIONS {
    take:
    ch_bed // meta and path

    main:
    TABIX_BGZIPTABIX (
        ch_bed
    )
    ch_bed_tbi = TABIX_BGZIPTABIX.out.gz_tbi

    emit:
    ch_bed_tbi
    
}
