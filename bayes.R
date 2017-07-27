library(rjags)

source("utils.R")

fit.bayes <- function(data, samples.file="samples.out"){
  # Run a MCMC simulation of the finishing skill model.
  # This takes several hours.
  # Refer to Kruschke p. 202-203 for the template.

  jags.data <- list(  # Prep data the way JAGS likes it
    goal=data$goal,
    distance=data$distance,
    cosangle=data$cosangle,
    head=data$head,
    throughball=data$throughball,
    cross=data$cross,
    big_chance=data$big_chance,
    fast_break=data$fast_break,
    open_play=data$open_play,
    freekick=data$freekick,
    difficult=data$difficult,
    player_id=data$player_id,
    league_id=data$league_id,
    total_shots=nrow(data),
    total_players=max(data$player_id),
    total_leagues=max(data$league_id)
  )

  jags.output <- jags.model(  # Set the model up
    "model.jags",
    data=jags.data,
    n.chains=1,
    n.adapt=750
  )
  update(jags.output, n.iter=750)  # Burn-in
  samples <- coda.samples(  # Draw 3000 samples from the posterior distributions
    jags.output,
    variable.names=c("player"),
    n.iter=3000
  )
  if (!is.null(samples.file)){
    saveRDS(samples, samples.file)
  }
}

extract.bayes.fit.summary <- function(samples){
  # Get summary statistics out of the coda object
  df <- as.data.frame(samples[[1]])
  ratings <- data.frame(row.names=NULL)
  for (i in 1:ncol(df)){
    sample <- df[, paste0("player[", i, "]")]
    record <- c(
      i,
      hdi.low(sample),
      median(sample),
      hdi.high(sample),
      postive.share(sample),
      hdi.low(sample, mass=0.75),
      hdi.high(sample, mass=0.75)
    )
    ratings <- rbind(ratings, record)
  }
  colnames(ratings) <- c("player_id", "low95", "mode", "high", "prob", "low75", "high75")

  return(ratings)
}

