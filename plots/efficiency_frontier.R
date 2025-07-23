# Load libraries
library(ggplot2)
library(dplyr)

# Create the dataset
cea_data <- tibble::tibble(
  Strategy = c("No screening", 
               "Risk-stratified sceening", 
               "Universal MRI", 
               "Universal SCED"),
  Cost = c(748.28, 1199.36, 1497.37, 1702.23),
  Effectiveness = c(27.26514, 27.26704, 27.26732, 27.26733),
  Incr_Cost_vs_No = c(0, 451.07, 749.09, 953.95),
  Incr_Eff_vs_No = c(0, 0.0019, 0.0022, 0.0022),
  Shape = c("No screening", "Risk-stratified screening", "Universal MRI", "Universal SCED")
)

cea_data$incr_eff<-cea_data$Incr_Eff_vs_No*1000
cea_data$incr_cost<-cea_data$Incr_Cost_vs_No*1000

# Order the strategies by effectiveness to draw the frontier correctly
cea_data <- cea_data |> arrange(incr_eff, incr_cost)

colors_subset = c("#DD4124FF",
                  "#00A0B0", 
                  #"#0F85A0FF",
                  "#00496FFF", 
                  "#D4AF37" # professional gold
                  #"#7BAFD4"   # soft blue-gray
                  # "#ED8B00FF",
                  # "#EDD746FF"
) 


library(showtext)
showtext_auto()
font_add("Calibri", "C:/Windows/Fonts/calibri.ttf")
showtext_opts(dpi = 300)

# Plot
efp<-ggplot(cea_data, aes(x = incr_eff, y = incr_cost)) +
  geom_line(color = "#D95F02", size = 0.4) + # Connect strategies
  geom_abline(intercept = 0, slope = 100000, color = "grey30", linetype = "dashed", size = 0.3) + # WTP line
  geom_point(aes(shape = Shape, fill=Shape), size = 3, stroke=0.1) + # Special shapes
  scale_shape_manual(values = c(21, 22, 23, 24)) + # Choose distinct shapes (circle, square, diamond, triangle)
  scale_fill_manual(values=colors_subset)+
  scale_y_continuous(labels = scales::dollar_format(prefix = "$", scale=(1/1000), suffix="K"))+
  #geom_text(aes(label = Strategy), vjust = -1.2, hjust = 0.5, size = 3.5) + # Labels
  labs(
    title = "",
    x = "Incremental effectiveness per 1k individuals, QALYs",
    y = "Incremental cost per 1k individuals, $",
    shape = "Strategy",
    fill = "Strategy"
  ) +
  theme(
      text = element_text(family = "Calibri", size = 8),  # BIGGER text
      axis.title.x = element_text(size = 8),
      axis.title.y = element_text(size = 8),
      axis.text.x = element_text(size = 6),
      axis.text.y = element_text(size = 6),
      axis.ticks = element_line(linewidth=0.1),
      legend.title = element_text(size = 6),
      legend.text = element_text(size = 6),
      legend.spacing.y = unit(0.1, "cm"),
      legend.key.height = unit(0.4, "cm"),
      plot.margin = unit(c(1,1,1,1), "cm"),
      panel.background = element_rect(fill="white"),
      panel.grid = element_line(color="grey80", linewidth=0.1),
      axis.line.x = element_line(color="black", linewidth=0.2),
      axis.line.y = element_line(color="black", linewidth=0.2),
      legend.position = "right")

ggsave("psa_plots/eff_frontier.png",plot=efp,width=6, height=3, units="in", dpi=300)

