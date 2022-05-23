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
        ch_truvari_giab_txt= TRUVARI_BENCHMARK.out.truvari_giab_report
        truvari_version = TRUVARI_BENCHMARK.out.versions

    ch_truvari_table = Channel.empty()
    ch_truvari_svg = Channel.empty()
    plot_version = Channel.empty()

    if(!params.skip_sv_report) {
        JL_2_CSV ( ch_truvari_giab_jl )
            ch_truvari_giab_csv = JL_2_CSV.out.csv

    }
    //PLOT_SV ( ch_truvari_giab_csv )
        //ch_truvari_table_size = PLOT_SV.out.truvari_table_size
        //ch_truvari_table_type = PLOT_SV.out.truvari_table_type
        //ch_truvari_table_sv = PLOT_SV.out.truvari_table_sv
        //ch_truvari_svg = PLOT_SV.out.truvari_plots
        //sv_plot_version = PLOT_SV.out.versions

    emit:
        ch_truvari_summary
        ch_truvari_vcf
        ch_truvari_log
        truvari_version
        //ch_truvari_table_size
        //ch_truvari_table_type
        //ch_truvari_table_sv
        //ch_truvari_svg
        //sv_plot_version

}
