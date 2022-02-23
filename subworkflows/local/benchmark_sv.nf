//
// BENCHMARK_SV: Benchmark structural variants
//

params.options = [:]

include { TRUVARI_BENCHMARK } from '../../modules/local/truvari_benchmark' addParams( options: params.options )
include { JL_2_CSV          } from '../../modules/local/jl_2_csv'          addParams( options: params.options )
include { PLOT_SV           } from '../../modules/local/plot_sv'           addParams( options: params.options )

workflow BENCHMARK_SV {
    take:
    ch_sample // tuple val(meta), path(bench), path(truth), path(fasta), path(fai), path(bed), path(tbi)

    main:

    ch_truvari_giab_jl = Channel.empty()

    TRUVARI_BENCHMARK ( ch_sample )
        ch_truvari_vcf = TRUVARI_BENCHMARK.out.truvari_vcf
        ch_truvari_log = TRUVARI_BENCHMARK.out.truvari_log
        ch_truvari_summary = TRUVARI_BENCHMARK.out.truvari_summary
        ch_truvari_giab_jl = TRUVARI_BENCHMARK.out.truvari_giab_jl
        truvari_version = TRUVARI_BENCHMARK.out.versions

    //ch_truvari_table = Channel.empty()
    //ch_truvari_svg = Channel.empty()
    //sv_plot_version = Channel.empty()

    if(!params.skip_sv_report) {
        JL_2_CSV ( ch_truvari_giab_jl )

        PLOT_SV ( JL_2_CSV.out.csv )

    }

    emit:
        ch_truvari_vcf
        ch_truvari_log
        ch_truvari_summary
        truvari_version
}
