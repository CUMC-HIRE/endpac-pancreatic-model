#  Pancreatic cancer screening in new-onset diabetes (NOD) populations

_A Novel Multimodal Approach to Pancreatic Cancer Screening Amongst Individuals with New Onset Diabetes_


Columbia University Irving Medical Center HIRE<br>
Sophie Wagner, sw3767@cumc.columbia.edu<br>

This repository contains the code and data for calibrating the natural history of pancreatic cancer (PC) in patients with new onset diabetes (NOD) and the decision-analytic screening model. The calibration is based on SEER data and NOD risk estimates from literature, aiming to estimate progression of PC in this population. 

### Calibration phases
1. Calibrate "average risk" with target := SEER PDAC incidence for ages 20-85
2. Calibrate increased risk for patients diagnosed with diabetes at age 60. NOD patients have 3-year risk of 0.09% (six to eightfold increased risk) following diagnosis. Target := SEER PDAC incidence for ages 60-63 only * increased hazard
3. Calibrate lower risk for NOD patients following 3-year high risk period, estimated to be at 1.8 times that of the average risk population. Target := SEER PDAC incidence for ages 63-85 * 1.8

### Screening model
The screening model is a decision-analytic model that compares the current status quo of no screening in NOD patients to various screening strategies. The model utilizes the estimated transition probabilities from the natural history calibration. Various PC screening strategies are compared for cost-effectiveness: natural history or no screening, universal MRI, universal SCED, and a multi-modal approach involving stratification of NOD patients based on clinical risk factors. 

## Directory
- `data/` : input data files, including SEER data and calibration targets. Note that SEER data files are not included in the repository, as they require registration for access. Dictionary and metadata files are included.
- `notebooks/` : Jupyter notebooks for data cleaning and natural history calibration
- `out/` : output files, including calibration results and plots
- `plots/` : R scripts for plotting TreeAge model outputs for publication
- `src/` : source code for calibration, including model definitions and calibration scripts (goodness of fit, model configuration, plotting, and helper functions)
- `TreeAge/` : TreeAge Pro files for the END-PAC NOD model
- `.gitignore` : specifies files and directories to be ignored by Git, such as Python cache files and SEER data files 
- `README.md` : this file, providing an overview of the project and its structure
