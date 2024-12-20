import numpy as np
import configs as c
import common_functions as func
from csaps import csaps

smoothL=csaps(c.ages_5y, c.seer_inc_5y['LocalU'], smooth=0.01)(c.ages_1y)
smoothR=csaps(c.ages_5y, c.seer_inc_5y['RegionalU'], smooth=0.01)(c.ages_1y)
smoothD=csaps(c.ages_5y, c.seer_inc_5y['DistantU'], smooth=0.01)(c.ages_1y)

def objective_5y(log):
    inc, _, _, _= log
    score = 0

    loc_5y, reg_5y, dis_5y = [func.get_5y_means(inc[stage, :]) for stage in [4, 5, 6]]

    score += np.square(loc_5y - c.seer_inc["LocalU"]).sum()
    score += np.square(reg_5y - c.seer_inc["RegionalU"]).sum()
    score += np.square(dis_5y - c.seer_inc["DistantU"]).sum()

    return score


def objective(log):
    inc, _, _, _= log
    score = 0
    
    # Define the weighting scheme
    weights = np.ones_like(inc[4, :])  # Initialize weights as 1 for all indices
    weights[:40] *= 2  # Double the weights for indices before age 60 (first 40 indices)

    # Calculate weighted scores
    score += (weights * np.square(inc[4, :] - smoothL)).sum()  # Local stage
    score += (weights * np.square(inc[5, :] - smoothR)).sum()  # Regional stage
    score += (weights * np.square(inc[6, :] - smoothD)).sum()  # Distant stage


    return score


def objective_nod(log):
    inc, _, _, _= log
    score = 0

    loc, reg, dis = [inc[stage,57:63] for stage in [4, 5, 6]]

    score += np.square(loc - c.seer_inc["LocalU"]).sum()
    score += np.square(reg - c.seer_inc["RegionalU"]).sum()
    score += np.square(dis - c.seer_inc["DistantU"]).sum()
    
    return score