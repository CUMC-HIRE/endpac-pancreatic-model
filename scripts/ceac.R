library(readxl)
library(ggplot2)
library(dplyr)
library(forcats)
library(scales)
library(RColorBrewer)
library(tidyverse)
d <- read_xlsx("treeage_output/psa_612.xlsx", sheet="CEAC")

colnames(d) <- c("WTP", "No screening", "Universal SCED", 
                 "Universal MRI", "Risk-stratified screening")

d_long <- d |> 
  pivot_longer(
    cols=!WTP,
    names_to = "Strategy",
    values_to = "Percent"
  )

d$diff <-  d$`No screening`-d$`Risk-stratified screening`
print(d |> filter(abs(diff)<0.1)) # IS Greater at $240k

print(d |> filter(WTP<=240000 & WTP>= 230000))

WTP1 = 230000
WTP2 = 240000
diff1 = d[d$WTP==WTP1,"diff"]
diff2 = d[d$WTP==WTP2,"diff"]

print(d |> filter(WTP==100000))

WTP_cross = WTP1 + ((0-diff1) / (diff2-diff1))*(WTP2-WTP1)
(WTP_cross <- as.numeric(WTP_cross$diff))

library(paletteer)

colors_subset = c("#DD4124FF",
                  "#0F85A0FF",
                  "#00496FFF", 
                  "#D4AF37" # professional gold
                  #"#7BAFD4"   # soft blue-gray
                  # "#ED8B00FF",
                  # "#EDD746FF"
                  ) 


library(showtext)
showtext_auto()
font_add("Calibri", "C:/Windows/Fonts/calibri.ttf")

# Define standard x-axis breaks (say every 50000), then add WTP_cross
breaks_x <- sort(c(seq(0, 300000, by = 100000), WTP_cross))


############## Labeled on end #################
### Not used in this analysis #################

p <-d_long |>
  ggplot(aes(x=WTP, y=Percent, color=Strategy)) +
  geom_line(size=0.5) +
  geom_vline(xintercept=100000, linetype="dashed", size=0.2)+
  #geom_vline(xintercept=WTP_cross, size=0.5)+
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_x_continuous(
    breaks = breaks_x,
    labels = scales::dollar_format()
  )+
  scale_color_manual(values=colors_subset)+
  labs(title = "", 
       x = "Willingness-to-pay threshold, $/QALY gained", 
       y = "Probability of being preferred strategy, %", 
       color = "Strategy") +
  #theme_minimal()+
  theme(axis.line.x = element_line(color="black", linewidth=0.2),
        axis.line.y = element_line(color="black", linewidth=0.2),
        axis.ticks = element_line(linewidth=0.2),
        text = element_text(family = "Calibri", size = 20),
        axis.text.x = element_text(size = 18),
        axis.text.y = element_text(size = 18),
        plot.margin = margin(10, 120, 10, 10),  # top, right, bottom, left
        panel.background = element_rect(fill="white"),
        panel.grid.major.x=element_blank(),
        panel.grid.major.y=element_line(color="grey80", linewidth=0.1),
        panel.grid.minor.y=element_line(color="grey80", linewidth=0.1),
        legend.position = "none"  # remove the legend
)


# Label data: get points at maximum WTP
label_data <- d_long |>
  group_by(Strategy) |>
  filter(WTP == max(WTP))

# Add a small manual nudge
label_data <- label_data |>
  mutate(
    nudge_y = case_when(
      Strategy == "Universal MRI" ~ 0.02,  # up by 1.5%
      Strategy == "Universal SCED" ~ -0.02, # down by 1.5%
      TRUE ~ 0  # no nudge for others
  ))

# Add labels with manual jitter
finalp <- p + 
  geom_text(
    data = label_data,
    aes(label = Strategy, y = Percent + nudge_y),
    hjust = -0.05,
    vjust = 0.5,
    size = 6,
    show.legend = FALSE,
    fontface = "bold"
  ) +
  coord_cartesian(clip = "off")


ggsave("psa_plots/ceac_426_label.png", width=5, height=3, units="in", dpi=300)

######## LEGEND ###############
p2 <- d_long |>
  ggplot(aes(x = WTP, y = Percent, color = Strategy)) +
  geom_line(size = 0.6) +   # smaller line size
  geom_vline(xintercept = 100000, linetype = "dashed", size = 0.3) +
  # geom_vline(xintercept = 240479, linetype = "dotted", color = "black", linewidth = 0.3)+
  scale_y_continuous(labels = scales::percent_format(accuracy = 1, suffix="")) +
  scale_x_continuous(
    breaks = breaks_x,
    labels = scales::label_comma(accuracy=1) #, scale=1/1000, suffix="K")
  ) +
  scale_color_manual(values = colors_subset) +
  labs(
    title = "", 
    x = "Willingness-to-pay threshold, $/QALY gained", 
    y = "Probability of being preferred strategy, %", 
    color = "Strategy"
  ) +
  # annotate("text", x = 100000, y = 1.05, label = "WTP threshold\n($100,000)", size = 2.5, hjust = -0.1, family = "Calibri") +
  # annotate("text", x = 243000, y = 1.05, label = "WTP value at \npreference switch\n($240,479)", size = 2.5, hjust = 0, family = "Calibri")+
  # coord_cartesian(clip = "off")+
  theme(
    text = element_text(family = "Calibri", size = 11),
    axis.title.x = element_text(size = 11, vjust=-1),
    axis.title.y = element_text(size = 11),
    axis.text.x = element_text(size = 11),
    axis.text.y = element_text(size = 11),
    axis.ticks = element_line(linewidth=0.1),
    legend.title = element_text(size = 11),
    legend.text = element_text(size = 11),
    legend.spacing.y = unit(0.05, "cm"),
    legend.key.height = unit(0.4, "cm"),
    axis.line.x = element_line(color = "black", linewidth=0.1),
    axis.line.y = element_line(color = "black",linewidth=0.1),
    panel.background = element_rect(fill = "white"),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(color = "grey80", linewidth = 0.1),
    panel.grid.minor.y = element_line(color = "grey80", linewidth = 0.1)
  )
ggsave("psa_plots/ceac_612b.png",plot=p2,width=8, height=4, units="in", dpi=300)