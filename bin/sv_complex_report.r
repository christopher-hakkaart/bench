#!/usr/bin/env Rscript

################################################
## COMPLEX REPORT ANALYSIS                    ##
################################################

#Analysis script for making csv tables and plots
#
#> pr_all_{workflowname}.csv
#> pr_type_{workflowname}.csv
#> pr_sizes_{workflowname}.csv
#> plot_counts_{workflowname).svg
#> plot_type_{workflowname).svg
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

if (length(args) < 2) {
  stop("Please input the giab.csv file and meta.id", call.=FALSE)
}

giab     <- read.csv(args[1])
workflow <- args[2]

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
## TIDY DATA FOR NICER OUTPUTS                ##
################################################

# Order factor size bins
giab$szbin <-
  factor(
    giab$szbin,
    levels = c(
      '<50',
      '[50,100)',
      '[100,200)',
      '[200,300)',
      '[300,400)',
      '[400,600)',
      '[600,800)',
      '[800,1k)',
      '[1k,2.5k)',
      '[2.5k,5k)',
      '>=5k'
    )
  )
giab$szbin <- gsub(")", "", giab$szbin)
giab$szbin <- gsub(",", "-", giab$szbin)
giab$szbin <- gsub("\\[", "", giab$szbin)
giab$szbin <-
  factor(
    giab$szbin,
    levels = c(
      '<50',
      '50-100',
      '100-200',
      '200-300',
      '300-400',
      '400-600',
      '600-800',
      '800-1k',
      '1k-2.5k',
      '2.5k-5k',
      '>=5k'
    )
  )

################################################
## MAKE DATA FRAMES                           ##
################################################

giab_all <- giab %>% group_by(state) %>%
  summarize(count = n()) %>%
  spread(key = state, value = count) %>%
  summarize(
    workflow = workflow,
    precision = tp / (tp + fp),
    recall = tp / (tp + fn),
    F1 = 2 * ((precision * recall) / (precision + recall))
  ) %>%
  replace_na(list(
    precision = 0,
    recall = 0,
    F1 = 0
  ))
colnames(giab_all) <- c("Workflow", "Precision", "Recall", "F1")

giab_type <- giab %>% group_by(state, svtype) %>%
  summarize(count = n()) %>%
  spread(key = state, value = count) %>%
  summarize(
    svtype = svtype,
    workflow = workflow,
    precision = tp / (tp + fp),
    recall = tp / (tp + fn),
    F1 = 2 * ((precision * recall) / (precision + recall))
  ) %>%
  replace_na(list(
    precision = 0,
    recall = 0,
    F1 = 0
  ))
colnames(giab_type) <- c("Type", "Workflow", "Precision", "Recall", "F1")

giab_size <- giab %>% group_by(state, svtype, szbin) %>%
  summarize(count = n()) %>%
  spread(key = state, value = count) %>%
  summarize(
    workflow = workflow,
    szbin = szbin,
    precision = tp / (tp + fp),
    recall = tp / (tp + fn),
    F1 = 2 * ((precision * recall) / (precision + recall))
  ) %>%
  replace_na(list(
    precision = 0,
    recall = 0,
    F1 = 0
  ))
colnames(giab_size) <- c("Type","Workflow","Size","Precision", "Recall", "F1")

################################################
## WRITE CSVS                                 ##
################################################
write.csv(giab_all,
          paste("table_complex_all_", workflow, ".csv", sep = ""))
write.csv(giab_type,
          paste("table_complex_type_", workflow, ".csv", sep = ""))
write.csv(giab_size,
          paste("table_complex_sizes_", workflow, ".csv", sep = ""))

################################################
## MAKE PLOTS                                 ##
################################################

a <-
  ggplot(subset(giab, state %in% c("tp", "fp", "fn")), aes(fill = svtype, x = state)) +
  geom_bar(position = 'dodge', color = "black") +
  ylab("Count") +
  xlab("State") +
  theme_classic(base_size = 12)

b <-
  ggplot(subset(giab, state %in% c("tp", "fp", "fn")), aes(fill = svtype, x = szbin)) +
  geom_bar(position = 'dodge', color = "black") +
  ylab("Count") +
  xlab("Size bin") +
  theme_classic(base_size = 12) +
  facet_grid(state ~ .)

c <-
backgroundF1 + geom_point(data=giab_size, aes(x=as.numeric(Recall), y=as.numeric(Precision),col=Size, shape=Type), alpha=30, cex=3) +
  ylab("Precision") +
  xlab("Recall") +
  theme_classic(base_size = 12) +
  guides(colour = guide_legend(ncol = 1))

################################################
## SAVE PLOTS                                 ##
################################################
svg(paste("plot_complex_counts_",workflow,".svg",sep=""),height=10, width=10)
a
dev.off()

svg(paste("plot_complex_type_",workflow,".svg",sep=""),height=10, width=10)
b
dev.off()

svg(paste("plot_complex_pr_",workflow,".svg",sep=""),height=10, width=10)
c
dev.off()