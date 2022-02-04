process HAPPY_BENCHMARK {
    tag "$meta.id"
    label 'process_high'

    conda     (params.enable_conda ? "python=2.7.17 bioconda::hap.py=0.3.14" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hap.py:0.3.14--py27h5c5a3ab_0' :
        'quay.io/biocontainers/hap.py:0.3.14--py27h5c5a3ab_0' }"

    input:
    tuple val(meta), val(variant_type), path(bench), path(truth), path(fasta), path(fai)

    output:
    path "*"                      , emit: happy_results
    path "versions.yml"           , emit: versions

    script:
    """
    hap.py \\
        $truth \\
        $bench \\
        -r $fasta \\
        -o ${meta.id}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hap.py: \$( echo 'hap.py 0.3.14' )
        python: \$( echo 'python 2.7.17' )
    END_VERSIONS
    """
}