process DECOMPRESS_GZIP {
    tag "$meta.id"
    label 'process_low'

    conda (params.enable_conda ? 'bioconda::gzip=1.12' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'kubran/ubuntu_essentials:v0' }"

    input:
        tuple val(meta), path(input)

    output:
    tuple val(meta), path("*.fa"), emit: fa

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def ref = "${input.getSimpleName()}.temp.fa"
    if (input.getExtension() == "gz")
        """
        gunzip -c -f $input > $ref
        """
    else
        """
        mv ${input.getName()} $ref
        """
}
