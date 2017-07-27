library(ggplot2)
library(dplyr)

make.top.plot <- function(ratings, topn=50){
  # Create a new player factor and sort it according to the skill estimate.
  ratings$player_name_aug <- sprintf("%s (%.0f%%)", ratings$player_name, 100*ratings$prob)
  ratings$player_name_aug <- factor(
    ratings$player_name_aug,
    levels = ratings$player_name_aug[order(ratings[, "mode"])]
  )
  ratings <- arrange(ratings, desc(mode))

  ggplot(head(ratings, topn), aes(x=mode, y=player_name_aug)) +
    geom_point(size=1.5) +
    geom_errorbarh(aes(xmin=low75, xmax=high75), size=0.25) +
    geom_vline(aes(xintercept=0), linetype='dotted') +
    ggtitle(sprintf("The top %d finishers", topn)) +
    labs(x="Player rating with 75% CI", y="Player name (P[skill > 0])") +
    theme(
      text=element_text(family='Palatino'),
      panel.grid.major.y=element_blank(),
      panel.background=element_blank(),
      axis.ticks.y=element_blank()
    )
}
