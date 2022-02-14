process TRUVARI_BENCHMARK {
    tag "$meta.id"
    label 'process_medium'

    conda     (params.enable_conda ? "bioconda::truvari=0.1.2018.08.10" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/truvari:0.1.2018.08.10--hdfd78af_2' :
        'quay.io/biocontainers/truvari:0.1.2018.08.10--hdfd78af_2' }"

    input:
    tuple val(meta), path(bench_gz), path(bench_tbi), path(truth_gz), path(truth_tbi), path(fasta), path(fai), path(bed), path(bed_gz), path(tbi)

    output:
    path "*.vcf"             , emit: truvari_vcf
    path "log.txt"           , emit: truvari_log
    path "summary.txt"       , emit: truvari_summary
    path "*versions.yml"     , emit: versions

    script:
    """
    truvari \\
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