process TRUVARI_BENCHMARK {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
        //if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        //  container "https://depot.galaxyproject.org/singularity/python:3.8.3"
        //} else {
        //   container "quay.io/biocontainers/python:3.8.3"
        //}

    input:
    tuple val(meta), path(bench_gz), path(bench_tbi), path(truth_gz), path(truth_tbi), path(fasta), path(fai), path(bed), path(bed_gz), path(tbi)

    output:
    tuple val(meta), path("${meta.id}/*.vcf")        , emit: truvari_vcf
    tuple val(meta), path("${meta.id}/*log*")        , emit: truvari_log
    tuple val(meta), path("${meta.id}/*summary.txt") , emit: truvari_summary
    //tuple val(meta), path("${meta.id}/*report.txt")  , emit: truvari_giab_report
    tuple val(meta), path("${meta.id}/*.jl")         , emit: truvari_giab_jl
    path("*versions.yml")                            , emit: versions

    script:
    def typeignore = params.typeignore ? "--typeignore" : ""
    def giabreport = params.giabreport ? "--giabreport" : ""
    def prog  = params.prog ? "--prog" : ""
    def gtcomp = params.gtcomp ? "--gtcomp" : ""
    def passonly = params.passonly ? "--passonly" : ""
    def no_ref = params.no_ref ? "--no_ref" : ""
    def multimatch = params.multimatch ? "--multimatch" : ""
    def includebed = params.includebed ? "--includebed $bed" : ""

    """
    python3 -m pip install truvari==3.0.0 

    truvari bench \\
    -b $truth_gz \\
    -c $bench_gz \\
    -f $fasta \\
    -o ${meta.id} \\
    -r $params.refdist \\
    -p $params.pctsim \\
    -P $params.pctsize \\
    -O $params.pctovl \\
    -B $params.buffer \\
    -s $params.sizemin \\
    -S $params.sizefilt \\
    --sizemax $params.sizemax \\
    $includebed \\
    $giabreport \\
    $prog \\
    $gtcomp \\
    $passonly \\
    $no_ref \\
    $multimatch


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        truvari: \$( truvari version 2>&1 | sed 's/Truvari //g' )
    END_VERSIONS
    """
}