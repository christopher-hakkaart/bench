//
// BENCHMARK_SHORT: Benchmark short variants
//

params.options = [:]

include { HAPPY_BENCHMARK } from '../../modules/local/happy_benchmark' addParams( options: params.options )

workflow BENCHMARK_SHORT {
    take:
    ch_sample //

    main:
    HAPPY_BENCHMARK ( ch_sample )
        ch_happy_metrics = HAPPY_BENCHMARK.out.happy_metrics
        ch_happy_rocs = HAPPY_BENCHMARK.out.happy_rocs
        ch_happy_runinfo = HAPPY_BENCHMARK.out.happy_runinfo
        ch_happy_summary = HAPPY_BENCHMARK.out.happy_summary
        happy_version = HAPPY_BENCHMARK.out.versions

    emit:
    ch_happy_metrics
    ch_happy_rocs
    ch_happy_runinfo
    ch_happy_summary
    happy_version
}