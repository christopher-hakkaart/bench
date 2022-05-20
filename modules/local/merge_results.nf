// Import generic module functions
process MERGE_RESULTS {
    tag "mergetest"
    label 'process_medium'

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    } else {
        container "quay.io/biocontainers/python:3.8.3"
    }

    input:
    path(ch_test)

    output:
    path("mergedtables.csv")        , emit: merged_csv

    script: //

    """
    awk 'FNR>1' ${ch_test.join(' ')} >> mergedtables.csv
    """
}
