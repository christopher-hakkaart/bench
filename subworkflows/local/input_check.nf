//
// Check input samplesheet and get read channels
//

params.options = [:]

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check' addParams( options: params.options )

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEET_CHECK ( samplesheet )
        .splitCsv ( header:true, sep:',' )
        .map { get_sample_info (it, params.genomes ) }
        .map { it -> [ it[0], it[1], it[2], it[3], it[4], it[5] ] }
        .set { ch_sample }

    emit:
    ch_sample // channel: [ meta, variant_type, genome, bench_set, truth_set, high_conf ]
}

// Function to check files exist and resolve genome is not provided

def get_sample_info(LinkedHashMap sample, LinkedHashMap genomeMap) {
    def meta = [:]
    meta.id  = sample.sample

    // Check bench and truth set files exist
    if (!file(sample.bench_set).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Bench set vcf file does not exist!\n${sample.bench_set}"
    }
    if (!file(sample.truth_set).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Truth set vcf file does not exist!\n${sample.truth_set}"
    }

    // Resolve fasta file if using iGenomes
    def fasta = false

    if (sample.genome) {
        if (genomeMap && genomeMap.containsKey(sample.genome)) {
            fasta = file(genomeMap[sample.genome].fasta, checkIfExists: true)
        } else {
            fasta = file(sample.genome, checkIfExists: true)
        }
    }

    // Resolve high confidence regions if using iGenomes
    def regions = false

    if (sample.high_conf) {
        regions = file( sample.high_conf )
    } else {
        if ( sample.genome == "GRCh37" && sample.variant_type == "SHORT") {
            regions = file ( "https://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/NA12878_HG001/NISTv4.2.1/GRCh37/HG001_GRCh37_1_22_v4.2.1_benchmark.bed" )
        } else if ( sample.genome == "GRCh38" && sample.variant_type == "SHORT" ) {
            regions = file ( "https://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/NA12878_HG001/NISTv4.2.1/GRCh37/HG001_GRCh37_1_22_v4.2.1_benchmark.bed" )
        } else {
            exit 1, "ERROR: Please check input samplesheet -> High confidence region for the genome do not exist!\n${sample.genome}\n${sample.high_conf}"
        }
    }

    return [ meta, sample.variant_type, fasta, sample.bench_set, sample.truth_set, regions ]
}
