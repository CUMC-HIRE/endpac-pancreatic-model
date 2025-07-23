library(readxl)
library(ggplot2)
library(dplyr)
library(forcats)
library(scales)
library(RColorBrewer)
library(tidyverse)
d <- read_xlsx("treeage_output/psa_612.xlsx", sheet="Monte Carlo CE Scatterplot")

d <- d |> mutate(
  Strategy = fct_recode(as.factor(Strategy),
                        "No screening"="No screening",
                        "Universal MRI"="Universal MRI",
                        "Universal SCED"="Universal SCED (90% spec)",
                        "Risk-stratified screening"="Risk Stratification with SCED (90% spec)")
)

library(showtext)
showtext_auto()
font_add("Calibri", "C:/Windows/Fonts/calibri.ttf")
showtext_opts(dpi = 300)
# one metric across strategies
d |> 
  ggplot(aes(x = Strategy, y = Cost)) +
  geom_violin(fill = "lightblue", alpha = 0.7) +
  scale_y_continuous(labels = scales::dollar_format(prefix = "$"))+
  theme_minimal() +
  labs(title = "Distribution of costs by strategy", x = "Strategy", y = "Cost")

d$eff <- d$Effectiveness * 1000

d |> 
  ggplot(aes(x = Strategy, y = eff)) +
  geom_violin(fill = "lightblue", alpha = 0.7) +
  scale_y_continuous(labels=comma_format())+
  theme_minimal() +
  labs(title = "Distribution of effectiveness by strategy", x = "Strategy", y = "Effectiveness (QALYs per 100k)")


# PSA scatterplot 
colors_subset = c("No screening" = "#DD4124FF", "Risk-stratified screening"="#0F85A0FF",
                  "Universal MRI" = "#00496FFF", "Universal SCED"="#D4AF37")

d$costs <- d$Cost*1000

d <- d |>  arrange(Iteration)

fig_plot<-d[0:100000,] |> 
  ggplot(aes(x = eff, y = costs, color = Strategy)) +
  geom_point(alpha = 0.8, size=0.5) +
  scale_color_manual(values=colors_subset)+
  scale_y_continuous(labels = scales::dollar_format(prefix = "", accuracy=0.1, scale=(1/1000000), suffix="M"))+
  scale_x_continuous(labels=comma_format())+
  #theme_minimal() +
  labs(title = "", 
       x = "Total effectiveness per 1k individuals, QALYs", y = "Total cost per 1k individuals, $")+
  theme(
    plot.margin = unit(c(1,1,1,1), "cm"),
    text = element_text(family = "Calibri"),
    panel.background = element_rect(fill="white"),
    panel.grid = element_blank(),
    axis.line.x = element_line(color="black", linewidth=0.2),
    axis.line.y = element_line(color="black", linewidth=0.2),
    axis.ticks = element_line(linewidth=0.2), 
)


fig_legend<-d[0:1000,] |> 
  ggplot(aes(x = eff, y = costs, color = Strategy)) +
  geom_point(alpha = 0.8, size=2) +
  scale_color_manual(values=colors_subset)+
  scale_y_continuous(labels = scales::dollar_format(prefix = "$", scale=(1/1000), suffix="K"))+
  scale_x_continuous(labels=comma_format())+
  #theme_minimal() +
  labs(title = "", 
       x = "Total effectiveness per 1k individuals, QALYs", y = "Total cost per 1k individuals, $")+
  theme(
    plot.margin = unit(c(1,1,1,1), "cm"),
    text = element_text(family = "Calibri"),
    panel.background = element_rect(fill="white"),
    panel.grid = element_blank(),
    axis.line.x = element_line(color="black", linewidth=0.2),
    axis.line.y = element_line(color="black", linewidth=0.2),
    axis.ticks = element_line(linewidth=0.2), 
  )
        

library(cowplot)

leg <- cowplot::get_legend(fig_legend)
final_fig <- cowplot::plot_grid(
  fig_plot + theme(legend.position="none"), 
  leg,
  ncol=2, rel_widths=c(3.5,1))
#final_fig

ggsave("psa_plots/psa_scatter_6_12b.png", bg= "white", plot = final_fig, width = 8, height = 4, dpi = 300)

        