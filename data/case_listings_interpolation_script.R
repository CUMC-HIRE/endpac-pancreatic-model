# Pancreatic Cancer Age and Stage Specific Hazard Function Using RSTMP2 Package
# Adapted from Matthew Prest, mp4090@cumc.columbia.edu
# Author: Sophie Wagner
# Contact: sw3767@cumc.columbia.edu
rm(list = ls()) # Clearing Environment and Plots
# dev.off() # Throws non-critical error if no plots exist
#Importing Packages
library(ggplot2) # For efficient plotting
library(dplyr)  # For dataframe manipulation
library(rstpm2) # For hazard modelling
library(survival)
library(forcats)
library(tidyr)
gc()
cat("\014") # Clearing Console

# Using Case Listing Data
df <- read.csv("C:\\repos\\pdac-calibration\\data\\s17_case_listings.csv")

df <- df |> 
  filter(Survival.months != "Unknown") |> 
  filter(SEER.historic.stage.A..1973.2015. != "<NA>") |> 
  mutate(
    SEER.cause.specific.death.classification = factor(
      SEER.cause.specific.death.classification,
      levels = c("Alive or dead of other cause", "Dead (attributable to this cancer dx)")
    ),
    SEER.other.cause.of.death.classification = factor(
      SEER.other.cause.of.death.classification,
      levels = c("Alive or dead due to cancer", "Dead (attributable to causes other than this cancer dx)")
    ),
    Vital.status.recode..study.cutoff.used. = factor(
      Vital.status.recode..study.cutoff.used.,
      levels = c("Alive", "Dead")
    ),
    SEER.historic.stage.A..1973.2015. = factor(
      SEER.historic.stage.A..1973.2015.,
      levels = c("Localized", "Regional", "Distant")
    ),
    Survival.months = as.numeric(Survival.months),
    Event = case_when(
      Vital.status.recode..study.cutoff.used. == "Alive" ~ 0,
      SEER.cause.specific.death.classification == "Dead (attributable to this cancer dx)" ~ 1,
      SEER.other.cause.of.death.classification == "Dead (attributable to causes other than this cancer dx)" ~ 2,
      TRUE ~ NA_real_
    ),
    Cancer_death = ifelse(SEER.cause.specific.death.classification=="Alive or dead of other cause", 0, 1),
    Other_death = ifelse(SEER.other.cause.of.death.classification=="Alive or dead due to cancer", 0, 1),
    All_death = ifelse(Vital.status.recode..study.cutoff.used.=="Alive", 0, 1),
    Age = as.numeric(substr(Age.recode.with.single.ages.and.85.,1,2))
  )


df2 <- df |> 
  arrange(Age) |> 
  mutate(
  AGE = factor(cut(Age, c(0, 49, 59, 64, 69, 74, 79, 84)), 
                     levels = c("(0,49]", "(49,59]", "(59,64]", "(64,69]", 
                                "(69,74]", "(74,79]", "(79,84]"), ordered = T),
  EVENT = ifelse(Survival.months > 120, 0, Event), 
  MONTHS = ifelse(Survival.months > 120, 120, Survival.months),
  YEARS = 1+MONTHS %/% 6
)

test<-df2 |> select(AGE, SEER.historic.stage.A..1973.2015., EVENT, YEARS) |> 
  rename(STAGE=SEER.historic.stage.A..1973.2015.) |> 
  drop_na()
test2 <- test |> select(STAGE, EVENT, YEARS) 

# Events for alive and death from ACM were too sparse to use Matt's stpm2 method.
# Instead, fit CSD hazard using pstpm2. Not based on age for simplicity
fit_CD <- pstpm2(Surv(YEARS, EVENT == 1) ~ STAGE, data = test)

# Prepare new data for prediction
new_data <- test |> distinct(STAGE, YEARS)

# Predict hazard function
new_data$CD_HAZARD <- predict(fit_CD, newdata = new_data, type = "hazard")

# Cleaning data up
names(new_data) <- c('STAGE', 'YEARS','CD_HAZARD')
new_data_refined <- new_data |> 
   mutate(YEARS = (YEARS-1) %/% 2) |> 
   arrange(STAGE, YEARS) |> 
   group_by(STAGE, YEARS) |> 
  summarise(CD_HAZARD = mean(CD_HAZARD))

# Remove unnecessary items
rm(test, test2, fit_CD)

# Convert hazards to transition probabilities
delta_t <- 1  # 1 year
new_data_transformed <- new_data_refined |> 
  mutate(
    CD_PROB_1Y = 1 - exp(-CD_HAZARD * delta_t),
  ) |> 
  select(STAGE, YEARS, CD_PROB_1Y)

write.csv(new_data_transformed, "C:\\repos\\pdac-calibration\\data\\s17_csd_transition_rates.csv", row.names = F)


### Optional code: formatting into matrix for TreeAge
## I did not run this since I decided against age-based transition probabilities
library(dplyr)
library(tidyverse)
df <- read.csv("C:\\repos\\pdac-calibration\\data\\s17_survival220.csv")

# Format AGE levels
# df <- df |> 
#   mutate(AGE = as.factor(AGE)) |> 
#   mutate(AGE = factor(AGE,
#                       levels = levels(AGE),
#                       labels = gsub(",", "_", gsub("[\\(\\)\\[\\]]", "", levels(AGE))))) |>
#   mutate(AGE = substr(AGE, 2,nchar(as.character(AGE)))) |>
#   mutate(AGE= substr(AGE, 1, nchar(as.character(AGE))-1)) |>
#   mutate(AGE_START = as.numeric(str_extract(AGE, "^[0-9]+")),  # Extract the first number
#          AGE_END = as.numeric(str_extract(AGE, "[0-9]+$"))) |>
#   mutate(AGE_START = ifelse(AGE_START==0, 20, AGE_START))


dfloc <- df |> 
  filter(STAGE=="Localized") |> 
  select(AGE, YEARS, CD_PROB_1Y) |> 
  pivot_wider(names_from = AGE, names_prefix = "AGE_", values_from=CD_PROB_1Y) 

dfreg <- df |> 
  filter(STAGE=="Regional") |> 
  select(AGE, YEARS, CD_PROB_1Y) |> 
  pivot_wider(names_from = AGE, names_prefix = "AGE_", values_from=CD_PROB_1Y)

dfdis <- df |> 
  filter(STAGE=="Distant") |> 
  select(AGE, YEARS, CD_PROB_1Y) |> 
  pivot_wider(names_from = AGE, names_prefix = "AGE_", values_from=CD_PROB_1Y)


write.csv(dfloc, "C:\\repos\\pdac-calibration\\data\\s17_probs_loc.csv", row.names = F)
write.csv(dfreg, "C:\\repos\\pdac-calibration\\data\\s17_probs_reg.csv", row.names = F)
write.csv(dfdis, "C:\\repos\\pdac-calibration\\data\\s17_probs_dis.csv", row.names = F)
