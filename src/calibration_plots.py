import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import common_functions as func
import configs as c
import os
from datetime import datetime

def extract_transition_probs(tmat, type="markov", metric="all", age_range = c.ages_5y, save=False, outpath=c.OUTPUT_PATHS['tps'], timestamp=None):
    """
    Extracts and optionally saves transition probabilities from a transition matrix.
    
    Parameters:
        tmat (numpy.ndarray): Transition probability matrix of shape (n_ages, n_states, n_states).
        type (str): Type of model ("markov" or other). Determines age range.
        save (bool): Whether to save the output as a CSV file.
        outpath (str): Path to save the CSV file. Required if save=True.
        timestamp (str): Custom timestamp for the filename. Defaults to current datetime.
    
    Returns:
        pd.DataFrame: Transition probabilities dataframe.
    """
    
    tmat = convert_to_conditional_probs(tmat) if type == "treeage" else tmat
    
    data = []
    df = None 
    
    if metric == "all":
        for (from_idx, to_idx), (from_state, to_state) in c.transitions_itos.items():
            for age, probs in zip(age_range, tmat[:, from_idx, to_idx]):
                data.append({
                    "Age": age,
                    "From State": from_state,
                    "To State": to_state,
                    "Probability": probs
                })
        
        df = pd.DataFrame(data)
    
        if save:
            timestamp = timestamp if timestamp is not None else datetime.now().strftime("%Y%m%d_%H%M")
            name = f"{timestamp}_tps_{type}" if timestamp is not None else f"tps_"
            os.makedirs(outpath, exist_ok=True)
            df.to_csv(f"{outpath}/{name}.csv", header=True)
        
    elif metric == "avg":
        for (from_idx, to_idx), (from_state, to_state) in c.transitions_itos.items():
            probs = [round(p,5) for p in tmat[:, from_idx, to_idx]]
            data.append({
                "From State": from_state,
                "To State": to_state,
                "Age 30": probs[10],
                "Age 75": probs[-10],
                 "Min": min(probs),
                 "Max": max(probs),
                 "Avg": round(np.mean(probs),5)
            })
        df = pd.DataFrame(data)
    
    else:
        print("Wrong metric specified in extract_transition_probs. Need [avg, all]")
    
    return df
        

def plot_vs_seer(inc_adj, seer_inc, save_imgs=False, show_plot=False, outpath=c.OUTPUT_PATHS["plots"], timestamp=None):
    """Plot model incidence by stage vs. SEER calibration incidence

    Args:
        inc_adj (matrix): output incidence log from run_markov
        seer_inc (df): item of comparison
    """
    x_values = np.arange(20, inc_adj.shape[1]+20, 1)

    # Plot yearly incidence by stage
    plt.plot(seer_inc["Age"], seer_inc["LocalU"], label=f"Local (SEER)", color="b", linestyle="dotted")
    plt.plot(seer_inc["Age"], seer_inc["RegionalU"], label=f"Regional (SEER)", color="r", linestyle="dotted")
    plt.plot(seer_inc["Age"], seer_inc["DistantU"], label=f"Distant (SEER)", color="g", linestyle="dotted")
    plt.plot(x_values, inc_adj[4, :], label="Local (Model)", color="b")
    plt.plot(x_values, inc_adj[5, :], label="Regional (Model)", color="r")
    plt.plot(x_values, inc_adj[6, :], label="Distant (Model)", color="g")
    plt.legend()
    plt.title("Incidence of Local, Regional, and Distant States")
    plt.xlabel("Time Point / Age Group")
    plt.ylabel("incidence")
    if save_imgs:
        plt.savefig(f"{outpath}/{timestamp}_inc_stage.png")  # Save figure
        plt.close()
    if show_plot:
        plt.show()
    else:
        plt.close()


def plot_vs_seer_total(inc_adj, seer_inc, save_imgs=False, show_plot=False, outpath=None, timestamp=None):
    x_values = np.arange(20,inc_adj.shape[1]+20, 1)

    plt.plot(seer_inc["Age"], seer_inc["LRDU Rate Smoothed"], label="SEER", color="b", linestyle="dotted")
    plt.plot(x_values, np.sum(inc_adj[4:7, :], axis=0), label="Model", color="b")
    plt.legend()
    plt.title("Total Incidence (L+R+D)")
    plt.xlabel("Time Point / Age Group")
    plt.ylabel("incidence")
    if save_imgs:
        plt.savefig(f"{outpath}/{timestamp}_inc_total.png")  # Save figure
    if show_plot:
        plt.show()
    else:
        plt.close()


def plot_params(markov_tmat, treeage_tmat=None, save_imgs=False, show_plot=False, outpath=None, timestamp=None):
    
    params = c.transitions_itos  # Transition state mappings
    n_params = len(params)  # Number of transition parameters
    
    # Define grid layout
    ncols = 3
    nrows = (n_params + ncols - 1) // ncols  # Ensure enough rows for all parameters
    
    fig, axes = plt.subplots(nrows, ncols, figsize=(10, 2.5 * nrows), constrained_layout=True)
    axes = axes.flatten()  # Flatten axes array for easier indexing
    age_bucket_midpts = [22.5, 27.5, 32.5, 37.5, 42.5, 47.5, 52.5, 57.5, 62.5, 67.5, 72.5, 77.5, 82.5]
    markov_tmat_5y = markov_tmat[2::5, :, :]
    
    for ax, ((from_idx, to_idx), (from_state, to_state)) in zip(axes, params.items()):
        # Plot TreeAge (line) and Markov (points)
        if treeage_tmat is not None:
            ax.plot(np.linspace(20, 100, treeage_tmat.shape[0]), treeage_tmat[:, from_idx, to_idx], 
                    label="TreeAge", linestyle="--", alpha=0.5)
        ax.scatter(age_bucket_midpts, markov_tmat_5y[:, from_idx, to_idx], 
                   label="Markov", color="blue", alpha=0.7)
        
        # Customize plot
        ax.set_title(f"{from_state} → {to_state}")
        ax.set_xlabel("Age")
        ax.set_ylabel("Transition Probability")
        ax.legend()
            
    if save_imgs:
        timestamp = timestamp if timestamp is not None else datetime.now().strftime("%Y%m%d_%H%M")
        name = f"{timestamp}_tps" if timestamp is not None else f"tps_"
        os.makedirs(outpath, exist_ok=True)
        fig.savefig(f"{outpath}/{name}.png")
    if show_plot:
        plt.show()
    else:
        plt.close()


def convert_to_conditional_probs(matrix):
    """
    Converts a transition matrix into conditional probabilities for TreeAge.
    
    Parameters:
        matrix (numpy.ndarray): Transition matrix of shape (n_ages, n_states, n_states).
    
    Returns:
        numpy.ndarray: Conditional transition matrix of the same shape.
    """
    conditional_matrix = np.copy(matrix)

    # Loop through all transitions to adjust probabilities
    for (from_idx, to_idx), (from_state, to_state) in c.transitions_itos.items():
        # Compute survival probability (1 - ACM)
        p_survive = 1 - matrix[:, from_idx, c.health_states_stoi['all_death']].clip(1e-10, 1.0)

        # Normalize by survival probability
        conditional_matrix[:, from_idx, to_idx] /= p_survive

        # If transition is progression (e.g., u_PDAC_x -> u_PDAC_x+1), normalize by p(no_dx)
        if from_idx in c.u_PDAC_states and to_idx == from_idx + 1:  # Progression
            dx_state = from_idx + 3  # Corresponding diagnosed state
            p_no_dx = 1 - matrix[:, from_idx, dx_state].clip(1e-10, 1.0)
            conditional_matrix[:, from_idx, to_idx] /= p_no_dx 
    return conditional_matrix


