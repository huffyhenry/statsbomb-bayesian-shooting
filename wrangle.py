import pandas as pd
import numpy as np


BIG5 = ("English Premier League", "Italian Serie A", "French Ligue 1",
        "Spanish La Liga", "German Bundesliga")


def wrangle(raw_data_file, outfile=None, leagues=BIG5):
    raw = pd.DataFrame.from_csv(raw_data_file, index_col=None)
    raw = raw[
        pd.notnull(raw.player) &
        (raw.season >= 2010) &
        ~(raw.situation == "penalty") &
        raw.competition.isin(leagues)
    ]
    print("Loaded %d shots in total." % len(raw))
    players = list(raw.player.unique())
    print("There are %d unique players." % len(players))

    # Transform to polar(ish) coordinates
    raw['x'] = 1.05 * raw['x']
    raw['y'] = 0.68 * raw['y']
    raw['distance'] = np.sqrt((105.0 - raw['x'])**2 + (raw['y'] - 34.0)**2)
    raw['ldist'] = np.sqrt((105.0 - raw['x'])**2 + (raw['y'] - 0.68 * 45.2)**2)
    raw['rdist'] = np.sqrt((105.0 - raw['x'])**2 + (raw['y'] - 0.68 * 54.8)**2)
    raw['cosangle'] = (raw['ldist']**2 + raw['rdist']**2 - (0.68 * 9.6)**2)\
                      / (2.0 * raw['rdist'] * raw['ldist'])  # Law of cosines
    raw = raw[pd.notnull(raw.cosangle)]  # Drop NaNs if any were introduced

    # Recode player and league info
    raw["player_name"] = raw["player"]
    raw['alt_id'] = raw['shooter_id']
    raw['player_id'] = [players.index(s) + 1 for s in raw.player]
    raw['league_id'] = [leagues.index(s) + 1 for s in raw.competition]

    # Get dummy variables for all factors of interest
    raw['goal'] = np.where(raw['outcome'] == 'goal', 1, 0)
    raw['head'] = np.where(raw["body_part"] == "head", 1, 0)
    raw['throughball'] = np.where(raw["assist_type"] == "through-ball", 1, 0)
    raw['cross'] = np.where(raw["assist_type"] == "cross", 1, 0)
    raw['fast_break'] = np.where(raw["fast_break"], 1, 0)  # Loaded as bool
    raw['big_chance'] = np.where(raw["big_chance"], 1, 0)  # ditto
    raw['open_play'] = np.where(raw["situation"] == "open play", 1, 0)
    raw['freekick'] = np.where(raw["situation"] == "direct freekick", 1, 0)
    raw['difficult'] = np.where(raw['technique'] == 'regular', 0, 1)

    # Drop unused columns
    raw = raw[
        ["player_name", "player_id", "alt_id", "league_id", "goal",
         "distance", "cosangle",
         "head", "throughball", "cross", "fast_break", "big_chance",
         "open_play", "freekick", "difficult"]
    ]

    # Save & return
    if outfile is not None:
        raw.to_csv(outfile, index=False, float_format="%.3f")

    return raw

