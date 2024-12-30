import numpy as np
import configs as c
import common_functions as func

# Average risk object function
def objective(log):
    inc, _, _, _= log
    score = 0
    
    # Yearly incidence penalty
    score += np.square(inc[4, :] - c.seer_inc['LocalU']).sum()  # Local stage
    score += np.square(inc[5, :] - c.seer_inc["RegionalU"]).sum()  # Regional stage
    score += np.square(inc[6, :] - c.seer_inc["DistantU"]).sum()  # Distant stage

    return score

# NOD objective function
def objective_nod(log):
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
    

def objective_cp(tmat):
    score = 0
    cp = cancer_progression(tmat)
    score += np.square(cp-3.0).sum()
    return score
    
def cancer_progression(tmat):
    """
    Calculate time from preclinical local to preclinical distant. MFPT
    """
    p_12 = tmat[:, 1, 2] # loc to reg
    p_23 = tmat[:, 2, 3] # reg to dis
    p_11 = tmat[:, 1, 1] # stay loc
    p_22 = tmat[:, 2, 2] # stay reg
    p_33 = tmat[:, 3, 3] # stay dis
    
    cp = (1 + p_12 * (1 + p_23 * (1 / (1 - p_33))) * (1 / (1 - p_22))) * (1 / (1 - p_11))
    
    return cp
    
    
def sojourn_time_weighted(tm, metric="mean"):
    """
    Calculate  time spent in each path.
    """
    in_loc, in_reg, in_dis = [1/(1-tm[:, x, x]) for x in [1,2,3]]
    mloc = in_loc
    mreg = in_loc + in_reg
    mdis = (in_loc * in_reg * tm[:, 1, 2]) + in_dis
    
    if metric == "mean": # Mean across paths per age
        sj_time =  np.mean([mloc, mreg, mdis], axis=0)
    else: # Each path per age
        sj_time = np.array([mloc, mreg, mdis])
    
    return sj_time

def sojourn_time_weighted2(tm):
    """
    Calculate  time spent in each path, weighted by stage.
    """
    in_loc, in_reg, in_dis = [1/(1-tm[:, x, x]) for x in [1,2,3]]
    mloc = in_loc
    mreg = in_loc + (in_reg * tm[:, 1, 2])
    mdis = in_loc + (in_reg * tm[:, 1, 2]) + (in_dis * tm[:, 2, 3])
    sj_time = np.array([mloc, mreg, mdis])
    
    return sj_time

def sojourn_time_in_stage(tmat):
    """
    Calculate mean time in each state. Average over all states.
    """
    sojourn_times = np.zeros((3,len(c.ages_1y)))
    for i in np.arange(1,4,1):
        p_stay = tmat[:, i, i]
        sojourn_times[i-1] = 1 / (1 - p_stay)
    return sojourn_times