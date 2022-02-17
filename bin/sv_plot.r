#!/usr/bin/env Rscript

################################################
## REQUIREMENTS                               ##
################################################


## Plot summary statistics for truvariv3.0.0 summary.txt file


################################################
## LOAD LIBRARY                               ##
################################################

library(yaml)
library(data.table)
library(ggplot2)
library(scales)
library(dplyr)
library(cowplot)

################################################
## PARSE COMMAND-LINE PARAMETERS              ##
################################################

args = commandArgs(trailingOnly=TRUE)
if (length(args) < 2) {
  stop("Please input the meta.id and the truvari_summary channel", call.=FALSE)
}
# default output file
workflowname <- args[1]
cat(workflowname)
path         <- args[2]

################################################
## CREATE BACKGROUND PLOTTING FUNCTION        ##
################################################

plotF1 <- function(min = 0.1,
                   max = 0.9,
                   diff = 0.1) {
  p1 <- seq(.001, .999, .001)
  f1 <- seq(min, max, diff)
  
  result_x <- c()
  result_y <- c()
  result_label <- c()
  
  zahler <- 0
  label <- as.numeric(min)
  
  calcf1 <- function(x, y) {
    return((x * y) / ((2 * y) - x))
  }
  
  for (f1tmp in f1) {
    for (x in p1) {
      y <- calcf1(f1tmp, x)
      
      if (0 < y && y <= 1.5) {
        zahler <- zahler + 1
        if (y > 1) {
          y <- 1
          
        }
        result_x[zahler] <- x
        result_y[zahler] <- y
        result_label[zahler] <- label
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
  
  
  return(df[maxval,])
}

F1df <- plotF1()

################################################
## READ SUMMARY YAML                          ##
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
    limits = c(-0.05, 1.05),
    expand = c(0, 0),
    breaks = seq(0, 1, 0.2)
  ) +
  scale_y_continuous(
    expand = c(0, 0),
    breaks = seq(0, 1, 0.2),
    limits = c(-0.05, 1.1)
  ) +
  theme_bw() +
  xlab('Recall') +
  ylab('Precision') +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()) +
  geom_text(
    data = annoF1,
    aes(
      x = x + 0.02,
      y = y,
      label = paste('f=', as.numeric(group)),
      fontface = 'italic'
    ),
    color = "grey",
    size = 4
  ) +
  theme(axis.text=element_text(size=20),
        axis.title=element_text(size=20),
        plot.title = element_text(size=30,hjust = 0.5)
        )

################################################
## READ SUMMARY YAML                          ##
################################################

dat <- suppressWarnings(read_yaml(file = 'W:/users/ahhakkc1/projects/SV_Benchmark/WGGC/results_GHGA/results/summary.txt'))

################################################
## PLOT PR                                    ##
################################################

all<-backgroundF1 + geom_point(data=as.data.frame(dat), aes(x=as.numeric(recall), y=as.numeric(precision)), alpha=30, cex=3) +
  theme() +
  guides(colour = guide_legend(ncol = 1)) +
  ggtitle( workflowname ,)
  
svg(paste("SummaryPlot_", workflowname, ".svg", sep=""),height=10, width=10)
all
dev.off()

################################################
## MAKE CSV                                   ##
################################################

write.csv(x = as.data.frame(dat),file = paste("SummaryPlot_",workflowname,".csv",sep=""))
          