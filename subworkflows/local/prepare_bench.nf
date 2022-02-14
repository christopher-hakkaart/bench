//
// Prepare bench set
//

params.options = [:]
params.genome_options = [:]

include { REMOVE_CHR  } from '../../modules/local/remove_chr'                       addParams( options: params.options )
include { TABIX_BGZIP } from '../../modules/nf-core/modules/tabix/bgzip/main'       addParams( options: params.genome_options )
include { TABIX_TABIX } from '../../modules/nf-core/modules/tabix/tabix/main'       addParams( options: params.genome_options )

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
    bench_gz = TABIX_BGZIP.out.gz
    
    /*
     * TABIX truth file
     */
    TABIX_TABIX (
        bench_gz
    )
    bench_tbi = TABIX_TABIX.out.tbi

    /*
     * Revert rename using meta
     */
    bench_gz
        .join(bench_tbi, by: [0] )
        .set { bench_gz_tbi }
    

    bench_gz_tbi.map{ meta, gz, tbi ->
        [meta, gz, tbi]
        }
    .set{ch_bench}

    emit:
    ch_bench
}