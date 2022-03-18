// Import generic module functions
process MERGE_RESULTS {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    } else {
        container "quay.io/biocontainers/python:3.8.3"
    }

    input:
    tuple val(meta), path(table)

    output:
    path("*csv")        , emit: merged_csv

    script: // 
    """
    cat $table >> merged_summary.csv
    """
}
