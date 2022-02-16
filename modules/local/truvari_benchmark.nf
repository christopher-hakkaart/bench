process TRUVARI_BENCHMARK {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
        if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
          container "https://depot.galaxyproject.org/singularity/python:3.8.3"
        } else {
           container "quay.io/biocontainers/python:3.8.3"
        }

    input:
    tuple val(meta), path(bench_gz), path(bench_tbi), path(truth_gz), path(truth_tbi), path(fasta), path(fai), path(bed), path(bed_gz), path(tbi)

    output:
    path "${meta.id}/*.vcf"  , emit: truvari_vcf
    path "${meta.id}/*log*"           , emit: truvari_log
    path "${meta.id}/*summary.txt"       , emit: truvari_summary
    path "*versions.yml"     , emit: versions

    script:
    """
    python3 -m pip install Truvari

    truvari bench \\
    -b $truth_gz \\
    -c $bench_gz \\
    -f $fasta \\
    -o ${meta.id} \\
    --includebed $bed \\
    --passonly

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        truvari: \$( truvari version 2>&1 | sed 's/Truvari //g' )
    END_VERSIONS
    """
}