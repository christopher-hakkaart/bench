process HAPPY_BENCHMARK {
    tag "$meta.id"
    label 'process_low'

    conda     (params.enable_conda ? "python=2.7.17 bioconda::hap.py=0.3.14" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hap.py:0.3.14--py27h5c5a3ab_0' :
        'quay.io/biocontainers/hap.py:0.3.14--py27h5c5a3ab_0' }"

    input:
    tuple val(meta), path(bench), path(bench_gz), path(truth), path(truth_gz), path(fasta), path(fai), path(bed), path(bed_gz), path(tbi)

    output:
    tuple val(meta), path("*metrics.json.gz") , emit: happy_metrics
    tuple val(meta), path("*.roc.*")          , emit: happy_rocs
    tuple val(meta), path("*runinfo.json")    , emit: happy_runinfo
    tuple val(meta), path("*summary.csv")     , emit: happy_summary
    path "*versions.yml"     , emit: versions

    script:
    def args = task.ext.args ?: ''
    def target_regions = params.skip_highconf ? "" : "-f $bed_gz"
    """
    hap.py \
        $truth \
        $bench \
        -r $fasta \
        -o ${meta.id} \
        $target_regions \
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hap.py: \$( echo 'hap.py 0.3.14' )
        python: \$(python --version 2>&1 | sed 's/^.*Python //; s/ :: Anaconda, Inc.*//' )
    END_VERSIONS
    """
}