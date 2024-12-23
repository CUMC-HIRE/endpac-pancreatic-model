import numpy as np
import configs as c
import common_functions as func
from csaps import csaps

smoothL=csaps(c.ages_1y, c.seer_inc_1y['LocalU'], smooth=0.01)(c.ages_1y)
smoothR=csaps(c.ages_1y, c.seer_inc_1y['RegionalU'], smooth=0.01)(c.ages_1y)
smoothD=csaps(c.ages_1y, c.seer_inc_1y['DistantU'], smooth=0.01)(c.ages_1y)

# SEER 5y incidence
def objective_avg_risk_5y(log):
    inc, _, _, _= log
    score = 0

    loc_5y, reg_5y, dis_5y = [func.get_5y_means(inc[stage, :]) for stage in [4, 5, 6]]

    score += np.square(loc_5y - c.seer_inc["LocalU"]).sum()
    score += np.square(reg_5y - c.seer_inc["RegionalU"]).sum()
    score += np.square(dis_5y - c.seer_inc["DistantU"]).sum()

    return score

# SEER 1y incidence
def objective_avg_risk_1y(log):
    inc, _, _, _= log
    score = 0
    

    # Calculate weighted scores
    score += np.square(inc[4, :] - smoothL).sum()  # Local stage
    score += np.square(inc[5, :] - smoothR).sum()  # Regional stage
    score += np.square(inc[6, :] - smoothD).sum()  # Distant stage

    return score

# NOD objective function
def objective(log):
    inc, _, _, _= log
    score = 0

    loc, reg, dis = [inc[stage,30:43] for stage in [4, 5, 6]]
    data = c.seer_inc_nod_full.query('Age > 49')

    score += np.square(loc - data['LocalU']).sum()
    score += np.square(reg - data['RegionalU']).sum()
    score += np.square(dis - data["DistantU"]).sum()
    
    return score

# Post-NOD objective function
def objective_post_nod(log):
    inc, _, _, _= log
    score = 0

    loc, reg, dis = [inc[stage,43:] for stage in [4, 5, 6]]
    data = c.seer_inc.query('Age > 63')

    score += np.square(loc - data['LocalU']).sum()
    score += np.square(reg - data['RegionalU']).sum()
    score += np.square(dis - data["DistantU"]).sum()