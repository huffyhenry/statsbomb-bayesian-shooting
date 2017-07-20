library(lme4)
library(dplyr)

shots <- read.csv("shots_clean.csv")


get.glmm.ratings <- function(data){
  # Scale continuous variables to zero mean and unit variance - lme4 likes that
  data$distance <- scale(data$distance, center=TRUE, scale=TRUE)
  data$cosangle <- scale(data$cosangle, center=TRUE, scale=TRUE)
  data$league_id <- as.factor(data$league_id)

  # Fit the GLMM
  model <- glmer(
    goal ~ distance + cosangle + head + throughball + cross +
      + big_chance + fast_break + open_play + freekick + difficult + league_id + (1|player_id),
    data=data,
    family=binomial,
    verbose=2
  )
  print(summary(model))

  # If glmer throws a convergence warning, check that this value is <0.001-ish
  # as per https://github.com/lme4/lme4/issues/120#issuecomment-39920269
  relgrad <- with(model@optinfo$derivs,solve(Hessian,gradient))
  print(paste("Magic relgrad test:", max(abs(relgrad))))

  # Extract random effect estimates with posterior variance
  eff <- ranef(model, condVar=TRUE)
  var <- attr(eff[[1]], "postVar")
  ratings <- data.frame(
    player_id = as.character(rownames(eff$player)),
    glmm_mode = eff$player[, "(Intercept)"],
    glmm_low = eff$player[, "(Intercept)"] - 1.96 * sqrt(var[1, 1, ]),
    glmm_high = eff$player[, "(Intercept)"] + 1.96 * sqrt(var[1, 1, ])
  )

  # Get and id->name player map with shot counts
  players <- shots %>%
    group_by(player_id) %>%
    summarize(player_name=first(player_name), alt_id=first(alt_id), N=n())

  # Add player names to the ratings data frame, sort and return
  ratings <- merge(ratings, players) %>% arrange(desc(glmm_mode))
  return(ratings)
}

