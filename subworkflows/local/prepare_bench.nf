//
// Prepare bench set
//

params.options = [:]
params.genome_options = [:]

include { REMOVE_CHR  } from '../../modules/local/remove_chr'                       addParams( options: params.options )
include { TABIX_BGZIP } from '../../modules/nf-core/modules/tabix/bgzip/main'       addParams( options: params.genome_options )


workflow PREPARE_BENCH {
    take:
    bench_ch // 

    main:
    /*
     * Remove chromosome from bench file
     */
    REMOVE_CHR (
        bench_ch
    )
    bench_nochr = REMOVE_CHR.out.vcf

    /*
     * BGZIP bench file
     */
    TABIX_BGZIP (
        bench_nochr
    )
    ch_bench = TABIX_BGZIP.out.gz


    emit:
    ch_bench
}