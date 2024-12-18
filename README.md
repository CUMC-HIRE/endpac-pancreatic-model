# PDAC Calibration
Natural history calibration for pancratic ductal adenocarcinoma (PDAC) in patients with new onset diabetes (NOD).

For use in PDAC NOD Early Detection project, led by Jeong Yang

Columbia University Irving Medical Center HIRE

Sophie Wagner, sw3767@cumc.columbia.edu


### Calibration phases
1. Calibrate "average risk" with target := SEER PDAC incidence for ages 20-85
2. Calibrate increased risk for patients diagnosed with diabetes at age 60. NOD patients have 3-year risk of 0.09% (six to eightfold increased risk) following diagnosis. Target := SEER PDAC incidence for ages 60-63 only * increased hazard
3. Calibrate lower risk for NOD patients following 3-year high risk period, estimated to be at 1.8 times that of the average risk population. Target := SEER PDAC incidence for ages 63-85 * 1.8
