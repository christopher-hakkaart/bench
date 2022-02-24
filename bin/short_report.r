#!/usr/bin/env Rscript

################################################
## SHORT VARIANT ANALYSIS                     ##
################################################

# Analysis script for making csv tables and plots:
#
# plot_short_pr_type_{workflowname}.svg
# plot_short_state_type_{workflowname}.svg
#

options(warn=-1)

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

if (length(args) < 2) {
  stop("Please input the giab.csv file and meta.id", call. = FALSE)
}

giab     <- read.csv(args[1])
workflow <- args[2]

################################################
## TIDY SUMMARY COLUMN NAMES                  ##
################################################

colnames(giab) <- c(
  "Type",
  "Filter",
  "Truth total",
  "True positives",
  "False negatives",
  "Query total",
  "False positives",
  "Unknown query",
  "False positives (GT)",
  "False positives (AL)",
  "Recall",
  "Precision",
  "Fraction NA",
  "F1 score",
  "Truth total (TI:TV)",
  "Query total (TI:TV)",
  "Truth total (HET:HOM)",
  "Query total (HET:HOM)"
)

################################################
## FIND REASONABLE PLOTTING MARGINS           ##
################################################

minPR <- min(c(giab$Recall,giab$Precision))

if (minPR > 0.95) {
  f1_low <- 0.95
  f1_high <- 0.99
  f1_breaks <- 0.01
  ax_low <- 0.95
  ax_high <- 1
  ax_breaks <- 0.01
  ax_mar <- 0.005
} else if (minPR > 0.9) {
  f1_low <- 0.9
  f1_high <- 0.99
  f1_breaks <- 0.01
  ax_low <- 0.9
  ax_high <- 1
  ax_breaks <- 0.02
  ax_mar <- 0.01
} else if (minPR > 0.5) {
  f1_low <- 0.6
  f1_high <- 0.95
  f1_breaks <- 0.05
  ax_low <- 0.6
  ax_high <- 1
  ax_breaks <- 0.05
  ax_mar <- 0.04
} else {
  f1_low <- 0.1
  f1_high <- 0.9
  f1_breaks <- 0.1
  ax_low <- 0.1
  ax_high <- 1
  ax_breaks <- 0.2
  ax_mar <- 0.05
}

################################################
## CREATE BACKGROUND PLOTTING FUNCTION        ##
################################################

plotF1 <- function(min = f1_low,
                   max = f1_high,
                   diff = f1_breaks) {
  p1 <- seq(.001, .999, .001)
  f1 <- seq(min, max, diff)
  
  result_x <- c()
  result_y <- c()
  result_label <- c()
  
  z <- 0
  label <- as.numeric(min)
  
  calcf1 <- function(x, y) {
    return((x * y) / ((2 * y) - x))
  }
  
  for (f1tmp in f1) {
    for (x in p1) {
      y <- calcf1(f1tmp, x)
      
      if (0 < y && y <= 1.5) {
        z <- z + 1
        if (y > 1) {
          y <- 1
          
        }
        result_x[z] <- x
        result_y[z] <- y
        result_label[z] <- label
      }
      
    }
    
    label <- as.numeric(label) + as.numeric(diff)
    
  }
  
  df <-
    data.frame(
      x = result_x,
      y = result_y,
      group = result_label,
      stringsAsFactors = FALSE
    )
  
  maxval <- rep(TRUE, nrow(df))
  
  for (d in 2:nrow(df)) {
    if (df$y[d] == df$y[d - 1]) {
      maxval[d - 1] <- FALSE
    }
  }
  
  
  return(df[maxval, ])
}

F1df <- plotF1()

################################################
## CREATE BACKGROUND                          ##
################################################

annoF1 <- F1df %>% group_by(group) %>% top_n(1, x)

backgroundF1 <- ggplot() +
  geom_line(
    data = F1df,
    aes(x = x, y = y, group = group),
    linetype = 'dashed',
    color = 'lightgray'
  ) +
  scale_x_continuous(
    limits = c(ax_low-ax_mar, ax_high+ax_mar),
    expand = c(0, 0),
    breaks = seq(ax_low, ax_high, ax_breaks)
  ) +
  scale_y_continuous(
    expand = c(0, 0),
    breaks = seq(ax_low, ax_high, ax_breaks),
    limits = c(ax_low-ax_mar, ax_high+(ax_mar/2),ax_breaks)
  ) +
  theme_bw() +
  xlab('Recall') +
  ylab('Precision') +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()) +
  geom_text(
    data = annoF1,
    aes(
      x = x + (ax_mar/3),
      y = y,
      label = paste('f=', as.numeric(group)),
      fontface = 'italic',
      na.rm=TRUE
    ),
    color = "grey",
    size = 4
  ) +
  theme(
    axis.text = element_text(size = 20),
    axis.title = element_text(size = 20),
    plot.title = element_text(size = 30, hjust = 0.5)
  )

################################################
## REFORMAT TABLE                             ##
################################################

short <-pivot_longer(giab, cols = c(`False negatives`, `False positives`, `True positives`), names_to = "State", values_to = "count")

################################################
## MAKE PLOTS                                 ##
################################################

short_state_type <-
ggplot(data=short, aes(x=State, y=count, fill=Type)) +
  geom_bar(stat="identity", color="black", position='dodge') +
    ylab("Count") +
    xlab("State") +
    theme_classic(base_size = 12) +
    facet_grid(rows = vars(Filter))
  
short_pr_type <-
  backgroundF1 + geom_point(
    data = giab,
    aes(
      x = as.numeric(Recall),
      y = as.numeric(Precision),
      col = Type,
      shape = Filter
    ),
    alpha = 30,
    cex = 3
  ) +
  ylab("Precision") +
  xlab("Recall") +
  theme_classic(base_size = 12) +
  guides(colour = guide_legend(ncol = 1))

################################################
## SAVE PLOTS                                 ##
################################################

svg(
  paste("plot_short_pr_type_", workflow, ".svg", sep = ""),
  height = 8,
  width = 8
)
short_pr_type
dev.off()


svg(
  paste("plot_short_state_type_", workflow, ".svg", sep = ""),
  height = 8,
  width = 8
)
short_state_type
dev.off()
