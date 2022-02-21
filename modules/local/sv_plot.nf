process SV_PLOT {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "conda-forge::r-base=4.0.3 conda-forge::r-cowplot=1.1.1 conda-forge::r-data.table=1.14.2 conda-forge::r-dplyr=1.0.7 conda-forge::r-ggplot2=3.3.5 conda-forge::r-scales=1.1.1 conda-forge::r-yaml=2.2.2" : null)
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/mulled-v2-02abbf3250c7d008f9d739d7e72ff16a64ae95fc:a440898f307c775f85c44c2812cb28afd74f011d-0' :
    //    'https://depot.galaxyproject.org/singularity/mulled-v2-02abbf3250c7d008f9d739d7e72ff16a64ae95fc:a440898f307c775f85c44c2812cb28afd74f011d-0' }"

    input:
    tuple val(meta), path(truvari_summary)

    output:
    path "*.svg"             , emit: truvari_plots
    path "*.csv"             , emit: truvari_table
    path "*versions.yml"     , emit: versions
    

    script:
    """
    sv_plot_function.r ${truvari_summary} ${meta.id}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(echo \$(R --version 2>&1) | sed 's/^.*R version //; s/ .*\$//')
        bioconductor-cowplot: \$(Rscript -e "library(cowplot); cat(as.character(packageVersion('cowplot')))")
        bioconductor-data.table: \$(Rscript -e "library(DESeq2); cat(as.character(packageVersion('data.table')))")
        bioconductor-dplyr: \$(Rscript -e "library(dplyr); cat(as.character(packageVersion('dplyr')))")
        bioconductor-ggplot2: \$(Rscript -e "library(ggplot2); cat(as.character(packageVersion('ggplot2')))")
        bioconductor-scales: \$(Rscript -e "library(scales); cat(as.character(packageVersion('scales')))")
        bioconductor-yaml: \$(Rscript -e "library(yaml); cat(as.character(packageVersion('yaml')))")
    END_VERSIONS
    """
}