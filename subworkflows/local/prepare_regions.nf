//
// Get benchset files
//
params.genome_options = [:]

include { TABIX_BGZIP } from '../../modules/nf-core/modules/tabix/bgzip/main'       addParams( options: params.genome_options )
include { TABIX_TABIX } from '../../modules/nf-core/modules/tabix/tabix/main'       addParams( options: params.genome_options )

workflow PREPARE_REGIONS {
    take:
    bed_ch // meta and path

    main:
    /*
     * Compress bed
     */
    TABIX_BGZIP (
        bed_ch
    )
    bed_gz = TABIX_BGZIP.out.gz

    /*
     * Index compressed bed
     */
    TABIX_TABIX (
        bed_gz 
    )
    bed_tbi = TABIX_TABIX.out.tbi

    bed_ch
    .join(bed_gz, by: [0] )
    .join(bed_tbi, by: [0] )
    .set { ch_bed }

    emit:
    ch_bed
}
