data{
  int N_players;
  int N_shots;
  int<lower=0, upper=1> goal[N_shots];
  row_vector[N_shots] x;
  row_vector[N_shots] y;
  int<lower=1, upper=N_players> player_id[N_shots];
}

parameters{
  real intercept;
  real x_main;
  real y_main;
  real player[N_players];
}

transformed parameters{
  row_vector[N_shots] basepred;  // Linear predictor without the player term

  basepred = intercept + x_main*x + y_main*y;
}

model{
  // Priors for the baseline predictor
  intercept ~ cauchy(0.0, 2.5);
  x_main ~ cauchy(0.0, 2.5);
  y_main ~ cauchy(0.0, 2.5);

  // Weakly informative (?) player skill prior centered at 0
  player ~ normal(0, 0.2);

  for (i in 1:N_shots){
    goal[i] ~ bernoulli_logit(basepred[i] + player[player_id[i]]);
  };
}
