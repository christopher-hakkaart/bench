//
// BENCHMARK_SV: Benchmark structural variants
//

params.options = [:]

include { TRUVARI_BENCHMARK } from '../../modules/local/truvari_benchmark' addParams( options: params.options )
//inlcude { SV_PLOT           } from '../../modules/local/sv_plot'           addParams( options: params.options )

workflow BENCHMARK_SV {
    take:
    ch_sample // tuple val(meta), path(bench), path(truth), path(fasta), path(fai), path(bed), path(tbi)

    main:
    TRUVARI_BENCHMARK ( ch_sample )
        ch_truvari_vcf = TRUVARI_BENCHMARK.out.truvari_vcf
        ch_truvari_log = TRUVARI_BENCHMARK.out.truvari_log
        ch_truvari_summary = TRUVARI_BENCHMARK.out.truvari_summary
        truvari_version = TRUVARI_BENCHMARK.out.versions

    ch_truvari_summary.view()

    //SV_PLOT ( ch_truvari_summary )
    //    ch_truvari_table = SV_PLOT.out.truvari_table
    //    ch_truvari_svg = SV_PLOT.out.truvari_plots
    //    sv_plot_version = SV_PLOT.out.versions

    emit:
        ch_truvari_vcf
        ch_truvari_log
        ch_truvari_summary
        truvari_version
        //ch_truvari_table
        //ch_truvari_svg
        //sv_plot_version
}
