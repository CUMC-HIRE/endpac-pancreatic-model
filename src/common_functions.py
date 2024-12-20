import numpy as np


# Common functions
def probtoprob(rate, a=1, b=12):
    return 1 - (1 - rate) ** (a / b)


def get_5y_means(inc):
    """
    Collapses array from shape s to s/5 get 5-y means.
    
    Args:
        inc: array of yearly incidence rate from model start to end.
    Returns:
        Collapsed array of shape (13,1)
    """
    shape = inc.shape[0] / 5
    reshaped = inc.reshape(int(shape), 5)
    aggregated = reshaped.mean(axis=1)
    
    return aggregated