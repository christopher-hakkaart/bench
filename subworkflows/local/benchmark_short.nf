//
// BENCHMARK_SHORT: Benchmark short variants
//

params.options = [:]

include { HAPPY_BENCHMARK } from '../../modules/local/happy_benchmark' addParams( options: params.options )

workflow BENCHMARK_SHORT {
    take:
    ch_sample // file: /path/to/samplesheet.csv

    main:
    HAPPY_BENCHMARK ( ch_sample )
    ch_benchmark_short = HAPPY_BENCHMARK.out.happy_results
    happy_version = HAPPY_BENCHMARK.out.versions
        

    emit:
    ch_benchmark_short // channel
    happy_version

}