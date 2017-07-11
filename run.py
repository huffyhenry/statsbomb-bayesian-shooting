import pandas as pd
import pystan as stan


def wrangle(raw_data_file, outfile=None, min_shots=50):
    raw = pd.DataFrame.from_csv(raw_data_file, index_col=None)
    raw = raw[~pd.isnull(raw.player)]
    print("Loaded %d shots in total." % len(raw))

    counts = raw.groupby('player').size().sort_values(ascending=False)
    players = list(counts.index)
    print("There are %d unique players." % len(players))

    def get_player_id(shot):
        if counts.loc[shot["player"]] < min_shots:
            return 1
        else:
            return players.index(shot["player"]) + 2

    raw["player_name"] = raw["player"]
    raw['player_id'] = raw.apply(get_player_id, axis=1)
    print("Proceeding with %d named players." % len(raw["player_id"].unique()))
    raw['x'] = 1.05 * raw['x']
    raw['y'] = abs(0.68 * (50.0 - raw['y']))
    raw['goal'] = raw.apply(
        lambda shot: 1 if shot["outcome"] == "goal" else 0,
        axis=1
    )
    raw = raw[["player_name", "player_id", "x", "y", "goal"]]
    if outfile is not None:
        raw.to_csv(outfile, index=False, float_format="%.3f")

    return raw


def compile(model_file):
    return stan.StanModel(model_file)


def fit(model, shots):
    players = shots["player_id"].unique()
    print("%d shots, %d distinct shooters." % (len(shots), len(players)))

    stan_data = {
        'N_players': len(players),
        'N_shots': len(shots),
        'x': list(shots.x),
        'y': list(shots.y),
        'goal': list(shots.goal),
        'player_id': list(shots.player_id)
    }

    return model.sampling(chains=4, iter=500, data=stan_data,
                          verbose=True)


data = wrangle("shots.csv", "shots_clean.csv", min_shots=100)
model = compile("model.stan")
fitted = fit(model, data)
