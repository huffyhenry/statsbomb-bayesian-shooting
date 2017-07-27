library(ggplot2)
library(dplyr)

top.n.plot <- function(ratings, n=50){
  # Create a new player factor and sort it according to the skill estimate.
  ratings$player_name_aug <- sprintf("%s (%.0f%%)", ratings$player_name, 100*ratings$prob)
  ratings$player_name_aug <- factor(
    ratings$player_name_aug,
    levels = ratings$player_name_aug[order(ratings[, "mode"])]
  )
  ratings <- arrange(ratings, desc(mode))

  ggplot(head(ratings, n), aes(x=mode, y=player_name_aug)) +
    geom_point(size=1.5) +
    geom_errorbarh(aes(xmin=low75, xmax=high75), size=0.25) +
    geom_vline(aes(xintercept=0), linetype='dotted') +
    ggtitle(sprintf("The top %d finishers", n)) +
    labs(x="Player rating w/ 75% CI", y="Player name w/ prob. of being above-average finisher") +
    theme(
      text=element_text(family='Palatino'),
      panel.grid.major.y=element_blank(),
      panel.background=element_blank(),
      axis.ticks.y=element_blank()
    )
}

probabilities.plot <- function(ratings, top.n=40, bottom.n=10){
  ratings <- arrange(ratings, desc(mode))
  graph.data <- rbind(head(ratings, top.n), tail(ratings, bottom.n))
  graph.data$player_name <- factor(
    graph.data$player_name,
    levels = graph.data$player_name[order(graph.data[, "mode"])]
  )

  ggplot(graph.data, aes(x=player_name, y=prob)) +
    geom_bar(stat="identity") +
    coord_flip()
}


