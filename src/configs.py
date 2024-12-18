import pandas as pd
import numpy as np
import common_functions as func
from scipy.interpolate import interp1d

# Global Parameters
starting_age = 20
max_age = 84
N = 100000  # Size of sample populations

OUTPUT_PATHS = {"logs": "../out/logs", "plots": "../out/plots", "tmats": "../out/tmats", "tps": "../out/tps"}

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
health_states_itos = dict((v, k) for k, v in health_states_stoi.items())

transitions_itos = {
    (0, 1): ("healthy", "u_PDAC_loc"),
    (1, 2): ("u_PDAC_loc", "u_PDAC_reg"),
    (2, 3): ("u_PDAC_reg", "u_PDAC_dis"),
    (1, 4): ("u_PDAC_loc", "d_PDAC_loc"),
    (2, 5): ("u_PDAC_reg", "d_PDAC_reg"),
    (3, 6): ("u_PDAC_dis", "d_PDAC_dis"),
}    
transitions_stoi = dict((v, k) for k, v in transitions_itos.items())

# Age indices for the model
ages_1y = np.arange(starting_age, max_age+1, 1)
age_layers_1y = np.arange(0, len(ages_1y), 1)
ages_5y = np.arange(starting_age, max_age, 5)
age_layers_5y = np.arange(0, len(ages_5y), 1)

# Initial population state
starting_pop = np.zeros((len(health_states_stoi), 1))
starting_pop[0, 0] = N  # Everyone starts in healthy state

# Load starting population log? 
# starting_pop_log = pd.read_csv("../out/logs/20241205_1310_pop60.csv").to_numpy()
# starting_inc_log = pd.read_csv("../out/logs/20241205_1310_inc60.csv").to_numpy()

# Inputs
acm_1y = pd.read_excel("../data/pdac_nod_model_inputs.xlsx", sheet_name="CDC lifetable").to_numpy()[:,1]
acm_5y = func.get_5y_means(acm_1y[:65])
model_inputs = pd.read_excel("../data/pdac_nod_model_inputs.xlsx", sheet_name="Model Inputs")
model_inputs.columns = model_inputs.iloc[1]
model_inputs = model_inputs[2:].reset_index(drop=True)
model_inputs_dict = dict(zip(model_inputs['Model Inputs'], model_inputs['Root Definition1']))
seer_inc = pd.read_csv("../data/seer_incidence_adj.csv")

start_params = {
    ("avg_risk", "u_PDAC_loc"): ((range(40), 0, 1), 1-(1-0.0011)**(1/25)),
    ("nod_risk", "u_PDAC_loc"): ((np.arange(40,44,1), 0, 1), 1-(1-0.009)**(1/3)),
    ("double_risk", "u_PDAC_loc"): ((np.arange(44,len(ages_1y),1), 0, 1), 0.00022),
    ("dia_risk", "u_PDAC_loc"):  ((np.arange(46,65,1), 0, 1), 0.0011),
    ("u_PDAC_loc", "u_PDAC_reg"):model_inputs_dict['p_Local_to_Regional_PC'],
    ("u_PDAC_reg", "u_PDAC_dis"):model_inputs_dict['p_Regional_to_Distant_PC'],
    ("u_PDAC_loc", "d_PDAC_loc"):model_inputs_dict['p_symptom_local'],
    ("u_PDAC_reg", "d_PDAC_reg"):model_inputs_dict['p_symptom_regional'],
    ("u_PDAC_dis", "d_PDAC_dis"):model_inputs_dict['p_symptom_distant'],
}
params = start_params.copy()
