process REMOVE_CHR {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? 'bioconda::bcftools=1.14' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools:1.14--h88f3f91_0' :
        'quay.io/biocontainers/bcftools:1.14--h88f3f91_0' }"

    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta), path("*.vcf") , emit: vcf
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = vcf.baseName
    """
    bcftools view \\
        --threads $task.cpus \\
        ${vcf} | sed s/chr// > ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}
