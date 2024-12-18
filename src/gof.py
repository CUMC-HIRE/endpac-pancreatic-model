import numpy as np
import configs as c
import common_functions as func

# Calculate score based on difference between model outputs and targets
def objective(log):
    inc, _, _, _= log
    score = 0

    seer_inc_local = c.seer_inc["LocalU"]
    loc_5y, reg_5y, dis_5y = [func.get_5y_means(inc[stage, :]) for stage in [4, 5, 6]]

    score += np.square(loc_5y - c.seer_inc["LocalU"]).sum()
    score += np.square(reg_5y - c.seer_inc["RegionalU"]).sum()
    score += np.square(dis_5y - c.seer_inc["DistantU"]).sum()


    return score
