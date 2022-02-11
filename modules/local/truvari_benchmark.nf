process TRUVARI_BENCHMARK {
    tag "$meta.id"
    label 'process_medium'

    conda     (params.enable_conda ? "bioconda::truvari=0.1.2018.08.10" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/truvari:0.1.2018.08.10--hdfd78af_2' :
        'quay.io/biocontainers/truvari:0.1.2018.08.10--hdfd78af_2' }"

    input:
    tuple val(meta), path(bench), path(truth), path(fasta), path(fai), path(bed), path(tbi)

    output:
    path "*.vcf"             , emit: truvari_vcf
    path "log.txt"           , emit: truvari_log
    path "summary.txt"       , emit: truvari_summary
    path "*versions.yml"     , emit: versions

    script:
    """
    truvari \\
        $truth \\
        $bench \\
        -r $fasta \\
        -f $bed \\
        -o ${meta.id}
    
    truvari bench \\
    -b $truth \\
    -c $bench \\
    -f $fasta \\ no zipped .fa
    -o ${meta.id} \\
    --includebed $bed \\ not zipped .bed
    --passonly

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        truvari: \$( truvari version 2>&1 | sed 's/Truvari //g' )
    END_VERSIONS
    """
}