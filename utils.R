library(dplyr)

hdi.low <- function(vector, mass=0.95){
  # Low end of `mass`% highest density interval
  idx <- floor(length(vector) * (1 - mass) / 2)
  return(sort(vector)[idx])
}

hdi.high <- function(vector, mass=0.95){
  # High end of `mass`% highest density interval
  idx <- ceiling(length(vector) - length(vector) * (1 - mass) / 2)
  return(sort(vector)[idx])
}

postive.share <- function(vector){
  # Fraction of entries greater than 0
  return(length(vector[vector > 0])/length(vector))
}

append.player.info <- function(ratings.df, shots.df){
  # Add player names and shot counts to ratings.df.
  # This method assumes that player_id column exists in ratings.df.
  return(
    shots.df %>%
      group_by(player_id) %>%
      summarize(player_name=first(player_name), alt_id=first(alt_id), N=n()) %>%
      merge(ratings.df)
  )
}
