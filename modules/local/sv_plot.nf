process SV_PLOT {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "conda-forge::r-base=4.0.3 bioconda::cowplot=1.1.1 bioconda::data.table=1.14.2 bioconda::dplyr=1.0.7 bioconda::ggplot2=3.3.5 bioconda::scales=1.1.1 bioconda::yaml=2.2.2" : null)  // Conda package
        if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
            container "https://depot.galaxyproject.org/singularity/mulled-v2-afe1e5f3879e265b14ec08dd3a1875df9c23630d:ec93fe5ff5457014204d1537f8b85458056510bb-0"                                                    // Singularity image
        } else {
            container "quay.io/biocontainers/mulled-v2-afe1e5f3879e265b14ec08dd3a1875df9c23630d:ec93fe5ff5457014204d1537f8b85458056510bb-0"                                                                          // Docker image
        }

    input:
    tuple val(meta), path(truvari_summary)

    output:
    path "*.svg"             , emit: truvari_plots
    path "*.csv"             , emit: truvari_table
    path "*versions.yml"     , emit: versions
    

    script:
    """
    Rscript sv_plot.r ${meta.id} ${truvari_summary}


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
