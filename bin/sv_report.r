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

if (length(args) < 2) {
  stop("Please input the giab.csv file and meta.id", call. = FALSE)
}

giab     <- read.csv(args[1])
workflow <- args[2]

################################################
## FIND REASONABLE PLOTTING MARGINS           ##
################################################

minPR <- min(c(giab$Recall,giab$Precision))

if (minPR > 0.95) {
  plotscore <- c(0.95, 0.99, 0.01)
  plotaxis <- c(0.95, 1, 0.01, 0.005)
} else if (minPR > 0.9) {
  plotscore <- c(0.90, 0.99, 0.01)
  plotaxis <- c(0.90, 1, 0.02, 0.01)
} else if (minPR > 0.5) {
  plotscore <- c(0.6, 0.95, 0.05)
  plotaxis <- c(0.6, 1, 0.05, 0.04)
} else {
  plotscore <- c(0.1, 0.9, 0.1)
  plotaxis <- c(0.1, 1, 0.2, 0.05)
}

################################################
## CREATE BACKGROUND PLOTTING FUNCTION        ##
################################################

plotF1 <- function(min = plotscore[1],
                   max = plotscore[2],
                   diff = plotscore[3]) {
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
    limits = c(plotaxis[1]-plotaxis[4], plotaxis[2]+plotaxis[4]),
    expand = c(0, 0),
    breaks = seq(plotaxis[1], plotaxis[2], plotaxis[3])
  ) +
  scale_y_continuous(
    expand = c(0, 0),
    breaks = seq(plotaxis[1], plotaxis[2], plotaxis[3]),
    limits = c(plotaxis[1]-plotaxis[4], plotaxis[2]+(plotaxis[4]/2), plotaxis[3])
  ) +
  theme_bw() +
  xlab('Recall') +
  ylab('Precision') +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()) +
  geom_text(
    data = annoF1,
    aes(
      x = x + (plotaxis[3]/3),
      y = y,
      label = paste('f=', as.numeric(group)),
      fontface = 'italic'
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
## TIDY SIZE BINS FOR NICER OUTPUTS           ##
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
## RESTRICT TO DEL AND INS                    ##
################################################

giab <- giab[giab$svtype %in% c("DEL", "INS"), ]

################################################
## MAKE DATA FRAMES                           ##
################################################

giab_sv <- giab %>% group_by(state) %>%
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
colnames(giab_sv) <- c("Workflow", "Precision", "Recall", "F1")

giab_sv_type <- giab %>% group_by(state, svtype) %>%
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
colnames(giab_sv_type) <-
  c("Type", "Workflow", "Precision", "Recall", "F1")

giab_sv_size <- giab %>% group_by(state, svtype, szbin) %>%
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
colnames(giab_sv_size) <-
  c("Type", "Workflow", "Size", "Precision", "Recall", "F1")

################################################
## WRITE CSVS                                 ##
################################################

write.csv(giab_sv,
          paste("table_sv_", workflow, ".csv", sep = ""),
          row.names=FALSE)
write.csv(giab_sv_type,
          paste("table_sv_type_", workflow, ".csv", sep = ""),
          row.names=FALSE)
write.csv(giab_sv_size,
          paste("table_sv_size_", workflow, ".csv", sep = ""),
          row.names=FALSE)

################################################
## MAKE PLOTS                                 ##
################################################

sv_state_type <-
  ggplot(subset(giab, state %in% c("tp", "fp", "fn")), aes(fill = svtype, x = state)) +
  geom_bar(position = 'dodge', color = "black") +
  scale_x_discrete(drop=FALSE) +
  scale_fill_discrete(drop=FALSE) +
  ylab("Count") +
  xlab("State") +
  theme_classic(base_size = 12) # Variant counts

sv_state_type_size <-
  ggplot(subset(giab, state %in% c("tp", "fp", "fn")), aes(fill = svtype, x = szbin)) +
  geom_bar(position = 'dodge', color = "black") +
  scale_x_discrete(drop=FALSE) + 
  scale_fill_discrete(drop=FALSE) +
  ylab("Count") +
  xlab("Size bin") +
  facet_grid(state ~ .) +
  theme_classic(base_size = 12) # Variant counts by type

sv_pr_type <-
  backgroundF1 + geom_point(
    data = giab_sv_type,
    aes(
      x = as.numeric(Recall),
      y = as.numeric(Precision),
      col = Type,
      shape = Type
    ),
    alpha = 30,
    cex = 3
  ) +
  ylab("Precision") +
  xlab("Recall") +
  theme_classic(base_size = 12) +
  guides(colour = guide_legend(ncol = 1))

sv_pr_type_size <-
  backgroundF1 + geom_point(
    data = giab_sv_size,
    aes(
      x = as.numeric(Recall),
      y = as.numeric(Precision),
      col = Size,
      shape = Type
    ),
    alpha = 30,
    cex = 3
  ) +
  ylab("Precision") +
  xlab("Recall") +
  guides(colour = guide_legend(ncol = 1)) +
  theme_classic(base_size = 12) # Variant counts by type

################################################
## SAVE PLOTS                                 ##
################################################
svg(
  paste("plot_sv_state_type_", workflow, ".svg", sep = ""),
  height = 8,
  width = 8
)
sv_state_type
dev.off()

svg(
  paste("plot_sv_state_type_size_", workflow, ".svg", sep = ""),
  height = 8,
  width = 8
)
sv_state_type_size
dev.off()

svg(
  paste("plot_sv_pr_type_", workflow, ".svg", sep = ""),
  height = 8,
  width = 8
)
sv_pr_type
dev.off()

svg(
  paste("plot_sv_pr_type_size_", workflow, ".svg", sep = ""),
  height = 8,
  width = 8
)
sv_pr_type_size
dev.off()
