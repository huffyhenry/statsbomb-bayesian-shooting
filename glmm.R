library(lme4)

fit.glmm <- function(data){
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

  return(model)
}

extract.glmm.fit.summary <- function(model){
  # Extract random effect estimates with posterior variance
  eff <- ranef(model, condVar=TRUE)
  var <- attr(eff[[1]], "postVar")
  return(
    data.frame(
      player_id = as.character(rownames(eff$player)),
      mode = eff$player[, "(Intercept)"],
      variance = sqrt(var[1, 1, ])
    )
  )
}

