import pandas as pd
import numpy as np
import common_functions as func
from scipy.interpolate import interp1d


"""
Global parameters
"""

risk = "avg"  #  CONFIG: ["avg", "nod", "double"]
risk_type = "endpac0"
starting_age = 20
max_age = 85
N = 100000  # Size of sample populations

OUTPUT_PATHS = {"logs": f"../out/{risk}/logs", 
                "plots": f"../out/{risk}/plots", 
                "tmats": f"../out/{risk}/tmats", 
                "tps": f"../out/{risk}/tps"}
if risk=="nod":
    OUTPUT_PATHS["ratios"]= f"../out/{risk}/ratios"
    
"""
Model setup
"""

# Health states
health_states_stoi = {
    "healthy": 0,
    "u_PDAC_loc": 1,
    "u_PDAC_reg": 2,
    "u_PDAC_dis": 3,
    "d_PDAC_loc": 4,
    "d_PDAC_reg": 5,
    "d_PDAC_dis": 6,
    "cancer_death": 7,
    "all_death": 8,
}
transitions_itos = {
    (0, 1): ("healthy", "u_PDAC_loc"),
    (1, 2): ("u_PDAC_loc", "u_PDAC_reg"),
    (2, 3): ("u_PDAC_reg", "u_PDAC_dis"),
    (1, 4): ("u_PDAC_loc", "d_PDAC_loc"),
    (2, 5): ("u_PDAC_reg", "d_PDAC_reg"),
    (3, 6): ("u_PDAC_dis", "d_PDAC_dis"),
}
health_states_stoi_nod = {
    "healthy": 0,
    "diagnosed": 1,
    "d_PDAC_loc": 2,
    "d_PDAC_reg": 3, 
    "d_PDAC_dis": 4,
    "cancer_death": 5,
    "all_death": 6
}
transitions_itos_nod = {
    (0, 1): ("healthy", "diagnosed")
}

# Additional information on health states
u_PDAC_states = [1,2,3]
d_PDAC_states = [4,5,6]
alive_states = [0,1,2,3,4,5,6]
death_states = [7,8]

# Age indices for the model
ages_1y = np.arange(starting_age, max_age+1, 1)
age_layers_1y = np.arange(0, len(ages_1y), 1)
ages_5y = np.arange(starting_age, max_age, 5)
age_layers_5y = np.arange(0, len(ages_5y), 1)

# Initial population state
starting_pop = np.zeros((len(health_states_stoi), 1))
starting_pop[0, 0] = N  # Everyone starts in healthy state

"""
Load inputs
"""

# ACM
acm_1y = pd.read_excel("../data/pdac_nod_model_inputs.xlsx", sheet_name="CDC lifetable").to_numpy()[:, 1]
acm_5y = np.mean(acm_1y[:65].reshape(-1, 5), axis=1)
acm_rates = acm_1y[:65]

# Starting params
model_inputs = pd.read_excel("../data/pdac_nod_model_inputs.xlsx", sheet_name="Model Inputs")
model_inputs.columns = model_inputs.iloc[1]
model_inputs = model_inputs[2:].reset_index(drop=True)
model_inputs_dict = dict(zip(model_inputs['Model Inputs'], model_inputs['Root Definition1']))

# Incidence data (risk-based)
seer_inc_1y_avg = pd.read_csv("../data/seer_incidence_1y.csv")
seer_inc_5y_avg = pd.read_csv("../data/seer_incidence_5y.csv")
seer_inc_1y_double = pd.read_csv("../data/seer_incidence_1y_double.csv")
seer_inc_nod_full = pd.read_csv("../data/seer_incidence_nod_full.csv")  # Ages 20-62
seer_inc_nod_only = pd.read_csv("../data/seer_incidence_nod.csv")  # Ages 57-62

"""
Model settings by risk
"""

if risk == "nod":
    starting_pop = pd.read_csv("../out/avg/logs/20250106_1626_pop_log.csv").to_numpy()[:,1:]
    starting_inc = pd.read_csv("../out/avg/logs/20250106_1626_inc_unadj.csv").to_numpy()
    starting_inc = starting_inc.T[1:, :]
    seer_inc = seer_inc_1y_avg
    if risk_type=="endpac3":
        seer_inc = seer_inc_nod_only
    elif risk_type=="endpac0":
        seer_inc = seer_inc_1y_avg
    # health_states_stoi = health_states_stoi_nod
    # transitions_itos = transitions_itos_nod
    pPDAC = [seer_inc[stage].mean() for stage in ['pLocal', 'pRegional', 'pDistant']]
    age_layers = age_layers_1y 
    ages_to_smooth = np.arange(50,63,1)
    age_layers_adj = age_layers_1y[40:46]
    ages_to_extract = ages_1y[40:46]  # Corresponds to ages 60-65
    
    acm_rates = acm_1y[40:46]
else:
    age_layers = age_layers_1y  # When to increment layer in run_markov()
    age_layers_adj = age_layers_5y  # Indices to adj in step()
    ages_to_smooth =  [22.5,27.5,32.5,37.5,42.5,47.5,52.5,57.5,62.5,67.5,72.5,77.5,82.5]
    ages_to_extract = ages_1y
    seer_inc = seer_inc_1y_double if risk=="double" else seer_inc_1y_avg
    
health_states_itos = dict((v, k) for k, v in health_states_stoi.items())
transitions_stoi = dict((v, k) for k, v in transitions_itos.items())
