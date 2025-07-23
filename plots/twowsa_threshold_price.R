library(readxl)
library(ggplot2)
library(dplyr)
library(forcats)
library(scales)
library(RColorBrewer)
library(tidyverse)
d <- read_xlsx("treeage_output/twowsa.xlsx", sheet="6-12b")


# 1. Filter: ICER less than 100,000, looking only at Risk Stratified
cea_thresholds <- d |> 
  mutate(Strategy = as.factor(Strategy)) |> 
  filter(ICER <= 100000 & Strategy == "Risk Stratification with SCED (90% spec)")

# 2. Find the maximum c_SCED per spec_SCED_90 that still satisfies WTP<100k
thresholds_summary <- cea_thresholds |> 
  group_by(spec_SCED_90) |>  # group by SCED specificity
  summarise(
    max_c_SCED = max(c_SCED),  # get max c_SCED under WTP
    .groups = 'drop'
  )


# Put specificity in hundreds instead of decimal
thresholds_summary$spec_SCED_90<-thresholds_summary$spec_SCED_90*100
thresholds_summary_ints <- thresholds_summary |> filter(spec_SCED_90 %% 1 == 0)

plot2w <- ggplot(thresholds_summary_ints, aes(x = max_c_SCED, y = factor(spec_SCED_90))) +
  geom_col(fill = "#00496FFF", width = 0.7) +
  geom_text(aes(label = paste0("$", round(max_c_SCED))),
            hjust = -0.2,
            size = 3, 
            family = "Calibri") +
  scale_x_continuous(
    #breaks = seq(0, 310, by = 50),
    expand = expansion(mult = c(0, 0.15))  # Leaves room for label text
  ) +
  labs(
    x = "Threshold price of SCED ($)",
    y = "SCED specificity (%)"
  ) +
  theme_minimal(base_family = "Calibri") +
  theme(
    text = element_text(size = 10),
    axis.title.x = element_text(size = 10, vjust = -1),
    axis.title.y = element_text(size = 10),
    axis.text.x = element_text(size = 8),
    axis.text.y = element_text(size = 8),
    axis.ticks = element_line(linewidth = 0.2),
    axis.line.x = element_line(color = "black", linewidth = 0.3),
    axis.line.y = element_line(color = "black", linewidth = 0.3),
    panel.grid.major.x = element_line(color = "grey80", linewidth = 0.2),
    panel.grid.minor = element_blank(),
    plot.margin = unit(c(0.5, 1, 0.5, 0.5), "cm")
  )


ggsave("2wsa_plots/threshold_price_plot.png", bg="white", plot=plot2w,width=4.5, height=3, units="in", dpi=300)



