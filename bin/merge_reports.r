#!/usr/bin/env Rscript

################################################
## SV REPORT                                  ##
################################################

# Analysis script for making csv tables and plots:
#
#
# table_sv_{workflowname}.csv
# table_sv_sizes_{workflowname}.csv
# table_sv_type_{workflowname}.csv
#
# plot_sv_state_type_{workflowname}.svg
# plot_sv_state_type_size_{workflowname}.svg
# plot_sv_pr_type_{workflowname}.svg
# plot_sv_pr_type_size_{workflowname}.svg
#

################################################
## LOAD LIBRARIES                             ##
################################################

suppressWarnings(library(ggplot2))
suppressWarnings(library(tidyr))
suppressWarnings(library(dplyr))
suppressWarnings(library(cowplot))

################################################
## PARSE COMMAND-LINE PARAMETERS              ##
################################################

args = commandArgs(trailingOnly = TRUE)

if (length(args) < 1) {
  stop("Tuple with file list missing", call. = FALSE)
}

fl     <- read.csv(args[1])

