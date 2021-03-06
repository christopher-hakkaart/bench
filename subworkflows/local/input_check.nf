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

// Check files exist and resolve genome if it is not provided
def get_sample_info(LinkedHashMap sample, LinkedHashMap genomeMap) {

    // Check bench set files exist
    if (!file(sample.bench_set).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Bench set vcf file does not exist!\n${sample.bench_set}"
    }

    // Resolve truth set file if not provided
    if (sample.truth_set) {
        truth_set = file( sample.truth_set )
    } else {
        if ( sample.genome == "GRCh37" && sample.variant_type == "SHORT") {
            truth_set = file ( "https://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/NA12878_HG001/NISTv4.2.1/GRCh37/HG001_GRCh37_1_22_v4.2.1_benchmark.vcf.gz" )
        } else if ( sample.genome == "GRCh38" && sample.variant_type == "SHORT" ) {
            truth_set = file ( "https://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/NA12878_HG001/NISTv4.2.1/GRCh38/HG001_GRCh38_1_22_v4.2.1_benchmark.vcf.gz" )
        } else if ( sample.genome == "GRCh37" && sample.variant_type == "STRUCTURAL" ) {
            truth_set = file ( "https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/analysis/NIST_SVs_Integration_v0.6/HG002_SVs_Tier1_v0.6.vcf.gz" )
        } else {
            exit 1, "ERROR: Please check input samplesheet -> Truth set vcf file does not exist for ${sample.variant_type} and ${sample.genome}!\n"
        }
    }
    
    // Resolve fasta file using iGenomes if .fa file is not provided
    def fasta = false

    if (sample.genome) {
        if (genomeMap && genomeMap.containsKey(sample.genome)) {
            fasta = file(genomeMap[sample.genome].fasta, checkIfExists: true)
        } else {
            fasta = file(sample.genome, checkIfExists: true)
        }
    }

    // Resolve high confidence regions if not provided
    def regions = false

    if (sample.high_conf) {
        regions = file( sample.high_conf )
    } else {
        if ( sample.genome == "GRCh37" && sample.variant_type == "SHORT") {
            regions = file ( "https://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/NA12878_HG001/NISTv4.2.1/GRCh37/HG001_GRCh37_1_22_v4.2.1_benchmark.bed" )
        } else if ( sample.genome == "GRCh38" && sample.variant_type == "SHORT" ) {
            regions = file ( "https://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/NA12878_HG001/NISTv4.2.1/GRCh38/HG001_GRCh38_1_22_v4.2.1_benchmark.bed" )
        } else if ( sample.genome == "GRCh37" && sample.variant_type == "STRUCTURAL" ) {
            regions = file ( "https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/analysis/NIST_SVs_Integration_v0.6/HG002_SVs_Tier1_v0.6.bed" )
        } else {
            exit 1, "ERROR: Please check input samplesheet -> High confidence region for ${sample.variant_type} and ${sample.genome}!"
        }
    }

    // Make new meta with simple information
    def meta = [:]
    meta.id  = sample.sample
    meta.workflow = sample.sample
    meta.variant_type = sample.variant_type
    meta.genome  = file(sample.genome).simpleName
    meta.truth_set  = file(truth_set).simpleName
    meta.high_conf  = file(regions).simpleName

    return [ meta, sample.variant_type, fasta, sample.bench_set, truth_set, regions ]
}
