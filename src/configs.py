import pandas as pd
import numpy as np
import common_functions as func
from scipy.interpolate import interp1d

# Global Parameters
risk = "avg"  # ["avg", "nod"]
starting_age = 20
max_age = 62 if risk == "nod" else 84  # Stop sim at 65 for NOD
N = 100000  # Size of sample populations
param_interval = 1  # 1 or 5-y change in age-based params

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
ages_1y_nod = np.arange(57,63,1)
age_layers_1y_nod = np.arange(0, len(ages_1y_nod), 1)

# When to switch to next layer in matrix during run_markov()
age_layers = age_layers_1y if param_interval == 1 else age_layers_5y  

# Parameters to adjust in step() function and row_normalize()
age_layers_adj = age_layers_1y_nod if risk == "nod" else age_layers_1y if param_interval == 1 else age_layers_5y
ages_to_smooth = np.arange(55,63,1) if risk == "nod" else [22.5,27.5,32.5,37.5,42.5,47.5,52.5,57.5,62.5,67.5,72.5,77.5,82.5]
ages_to_extract = ages_1y_nod if risk == "nod" else ages_1y if param_interval == 1 else ages_5y

# Initial population state
starting_pop = np.zeros((len(health_states_stoi), 1))
starting_pop[0, 0] = N  # Everyone starts in healthy state

# Load starting population log? 
# starting_pop_log = pd.read_csv("../out/logs/20241205_1310_pop60.csv").to_numpy()
# starting_inc_log = pd.read_csv("../out/logs/20241205_1310_inc60.csv").to_numpy()

# Inputs
acm_1y = pd.read_excel("../data/pdac_nod_model_inputs.xlsx", sheet_name="CDC lifetable").to_numpy()[:,1]
acm_5y = func.get_5y_means(acm_1y[:65])
acm_rates = acm_1y[:len(age_layers_1y)] if param_interval == 1 else acm_5y
model_inputs = pd.read_excel("../data/pdac_nod_model_inputs.xlsx", sheet_name="Model Inputs")
model_inputs.columns = model_inputs.iloc[1]
model_inputs = model_inputs[2:].reset_index(drop=True)
model_inputs_dict = dict(zip(model_inputs['Model Inputs'], model_inputs['Root Definition1']))
seer_inc_5y = pd.read_csv("../data/seer_incidence_5y.csv")
seer_inc_1y = pd.read_csv("../data/seer_incidence_1y.csv")
seer_inc_nod = pd.read_csv("../data/seer_incidence_nod.csv")  # NOTE: For ages 57-62
seer_inc = seer_inc_1y
