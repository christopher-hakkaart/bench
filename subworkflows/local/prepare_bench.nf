//
// Prepare bench set
//

params.options = [:]

include { REMOVE_CHR  } from '../../modules/local/remove_chr'        addParams( options: params.options )
include { TABIX_BGZIP } from '../../modules/local/tabix_bgzip'       addParams( options: params.options )


workflow PREPARE_BENCH {
    take:
    bench_ch // meta and path

    main:
    REMOVE_CHR (
        bench_ch
    )

    TABIX_BGZIP (
        REMOVE_CHR.out.vcf
    )
    ch_bench = TABIX_BGZIP.out.gz

    emit:
    ch_bench
}