#' Titer bar plots.
#'
#' \code{Barplot} plots the baseline and day 28 titers
#'
#'
#' 
#' @param dat_list a named list like the one returned by \code{\link{FormatTiters}}.
#' @param subjectCol the name of the column specifying a subject ID. Default is "SubjectID".
#' @param cols numeric specifying how many columns to layout plot
#' @param groupVar an optional character string specifying a grouping variable. May be either a variable in \code{dat_list} or an endpoint. Default is \code{NULL}
#' @param colors a vector of colors specifying bar colors. If \code{dat_list} contains more than 4 elements, you must specify your own colors.
#' @return (invisibly) a list of ggplot2 object(s).
#'
#' @import grid ggplot2 dplyr tidyr
#' @importFrom stats as.formula
#' 
#' @author Stefan Avey
#' @export
#' @examples
#' ## Prepare the data
#' titer_list <- FormatTiters(Year1_Titers)
#'
#' ## Bar plot of a single strain
#' Barplot(titer_list["A California 7 2009"])
#'
#' ## Bar plot of all 3 strains
#' Barplot(titer_list)
#'
#' ## Can improve readability of previous plot by separating into groups
#' ## For example, group by AgeGroup
#' Barplot(titer_list, groupVar = "AgeGroup")
Barplot <- function(dat_list, subjectCol = "SubjectID", cols = 1,
                    groupVar = NULL,
                    colors =
                      c("#A6CEE3", "#1F78B4", "#B2DF8A", "#33A02C",
                        "#FB9A99", "#E31A1C", "#FDBF6F", "#FF7F00"))
{
  if (sum(subjectCol == unlist(lapply(dat_list, colnames))) != length(dat_list)) {
    stop("Must specify a valid subject column name using the `subjecCol` argument")
  }
  plotList <- list()
  ## Convert list to data frame
  dat_df <- do.call(rbind.data.frame, dat_list) %>%
    gather("Condition", "titer", matches("^(Pre)|(Post)|(FC)$"))
  ## Determine which subjects/strains had a fold change of at least 4
  fcDat <- dat_df %>%
    filter(Condition == "FC") %>%
    mutate(fourFC = ifelse(titer >= log2(4), TRUE, FALSE)) %>%
    select_(subjectCol, "Strain", "fourFC")
  plotDat <- full_join(dat_df, fcDat, by = c(subjectCol, "Strain")) %>%
    filter(Condition != "FC") %>%
    mutate(Condition = factor(Condition, levels = c("Pre", "Post")))
  plotDat[[subjectCol]] <- factor(plotDat[[subjectCol]])
  lims <- c(min(plotDat$titer, na.rm = TRUE), max(plotDat$titer, na.rm = TRUE))
  ybreaks <- lims[1]:lims[2]
  if(!is.null(groupVar)) {
    if( (!groupVar %in% colnames(plotDat)) || length(groupVar) > 1) {
      stop("`groupVar` must be a length 1 character vector specifying a valid column name from an element of dat_list")
    }
    if (!is.factor(plotDat[[groupVar]])) {
      plotDat[[groupVar]] <- factor(plotDat[[groupVar]])
    }
    groupLevels <- levels(plotDat[[groupVar]])
    for(group in groupLevels) {
      ## Create a plot for each group
      toKeep <- plotDat[[groupVar]] == group
      pd <- plotDat[toKeep, ]
      gg <- ggplot(pd, aes_string(x = subjectCol) +
                     aes(y = titer,
                         group = interaction(Condition, Strain),
                         fill = interaction(Condition, Strain), color = fourFC)) +
        geom_hline(aes(yintercept = log2(40)), color = "grey20", alpha = 0.5) +
        geom_bar(stat = "identity", position = "dodge") +
        coord_cartesian(ylim = lims) +
        scale_color_manual(values = c("white", "black"),
                           name = "4 Fold Change", guide = FALSE) +
        scale_fill_manual(values = colors[1:(length(dat_list)*2)], name = "Day.Strain") +
        scale_y_continuous(breaks = ybreaks, labels = 2^ybreaks) +        
        ## ylab(expression("log"[2]("HAI Titer"))) +
        ylab("HAI Titer") +        
        theme_bw() +
        theme(strip.text =element_text(size = 16),
              axis.text = element_text(size = 14),
              axis.text.x = element_text(angle = 60, hjust = 1),          
              title=element_text(size=20, face="bold"))      
      if(any(plotDat[[groupVar]] == group)) {
        gg <- gg + facet_grid(as.formula(paste("~", groupVar)),
                              scales = "free_x", drop = TRUE)
      } else {
          gg <- gg + geom_blank()
        }
      if(group != groupLevels[length(groupLevels)]) {
        gg <- gg + xlab("")
      }
      plotList[[group]] <- gg
    }
  } else {
      gg <- ggplot(plotDat,
                   aes_string(x = subjectCol) +
                     aes(y = titer,
                         group = interaction(Condition, Strain),
                         fill = interaction(Condition, Strain), color = fourFC)) +
        geom_hline(aes(yintercept = log2(40)), color = "grey20", alpha = 0.5) +
        geom_bar(stat = "identity", position = "dodge") +
        coord_cartesian(ylim = lims) +
        scale_color_manual(values = c("white", "black"),
                           name = "4 Fold Change", guide = FALSE) +
        scale_fill_manual(values = colors[1:(length(dat_list)*2)], name = "Day.Strain") +
        scale_y_continuous(breaks = ybreaks, labels = 2^ybreaks) +
        ## ylab(expression("log"[2]("HAI Titer"))) +
        ylab("HAI Titer") +        
        theme_bw() +
        theme(strip.text =element_text(size = 16),
              axis.text = element_text(size = 14),
              axis.text.x = element_text(angle = 60, hjust = 1),          
              title=element_text(size=20, face="bold"))
      plotList[[1]] <- gg
    }
  Multiplot(plotlist = plotList, cols = cols)
  return(invisible(plotList))
}
