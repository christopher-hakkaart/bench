// Import generic module functions
process JL_2_CSV {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    } else {
        container "kubran/python3:v0"
    }

    input:
    tuple val(meta), path(jl)

    output:
    tuple val(meta), path("*csv")        , emit: csv

    script: // This script is bundled with the pipeline, in nf-core/bench/bin/
    """
    jl2csv.py \\
        -in $jl \\
        -out ${meta.id}.csv
    """
}
