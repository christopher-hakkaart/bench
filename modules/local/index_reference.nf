process INDEX_REFERENCE {

    conda     (params.enable_conda ? "bioconda::samtools=1.10" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.13--h8c37831_0' :
        'quay.io/biocontainers/samtools:1.13--h8c37831_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path(fasta), path('*.fai')         , emit: fai
    path  "versions.yml"                                , emit: versions

    script:
    """
    samtools faidx $fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}