library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(forcats)
library(readxl)

# Load and process data
df <- readxl::read_excel("treeage_output/owsa_6_9.xlsx", sheet="Sheet1")


# ONLY TEST CHARS
tornado_data <- df |> 
  filter(spread != 0 & var_name != "p_endpac0") |> 
  mutate(
    strat = factor(strat),
    low_impact = ev - icer_low,
    high_impact = icer_high - ev,
    low_label = ifelse(impact == "Increase", "Low estimate", "High estimate"),
    high_label = ifelse(impact == "Increase", "High estimate", "Low estimate"),
    spread = as.numeric(spread),
    var_label =  fct_recode(factor(`var_name`), 
                            NULL = "c_EUS_FNB",      
                            "MRI cost" = "c_MRI",                 
                            "SCED cost"= "c_SCED",
                            NULL = "c_CTscan",             
                            NULL = "c_local_terminal",    
                            NULL = "c_regional_terminal",   
                            NULL = "c_distant_terminal",             
                            NULL= "c_local_continuing",
                            NULL= "c_regional_continuing",
                            NULL= "c_distant_continuing",  
                            NULL= "c_local_firstyr",   
                            NULL= "c_regional_firstyr",
                            NULL= "c_distant_firstyr",    
                            NULL= "c_local_ACM" ,  
                            NULL=  "c_distant_ACM" ,
                            NULL= "c_regional_ACM",       
                            "MRI specificity" ="spec_MRI",            
                            "MRI sensitivity, local PC" ="sens_MRI_loc",
                            "MRI sensitivity, regional PC" ="sens_MRI_reg",          
                            "MRI sensitivity, distant PC" ="sens_MRI_dis",
                            "SCED specificity" ="spec_SCED_90",
                            "SCED sensitivity, local PC" ="sens_SCED_loc_90",      
                            "SCED sensitivity, regional PC" ="sens_SCED_reg_90", 
                            "SCED sensitivity, distant PC" ="sens_SCED_dis_90"  ,        
                            NULL = "_age_NOD_end" ,
                            NULL = "u_local_PC" ,   
                            NULL = "u_distant_PC",       
                            NULL = "u_regional_PC",
                            NULL = "c_EUS_complication",
                            "Probability of EUS complication" = "p_EUS_complication",
                            "EUS complication disutility" = "u_EUS_complication_value")
  ) |> 
  arrange(strat, desc(spread))

tornado_data <- tornado_data |> filter(!is.na(var_label))

# Define colors
colors = c("#DD4124FF",
           "#00496FFF")
# Define colors
impact_colors <- c("Low estimate" = colors[1], "High estimate" = colors[2])

# Tornado plot function
plot_tornado <- function(data, title, x_min = NULL, x_max = NULL, bar_width=NULL, ev_place=1, x_breaks=NULL, formatted_ev=NULL) {
  
  EV <- data$ev[1]
  if (is.null(formatted_ev)) formatted_ev <- scales::dollar(EV, accuracy=1)
  
  
  # Automatically determine x-axis limits if not provided
  if (is.null(x_min)) x_min <- min(data$icer_low) * 0.8
  if (is.null(x_max)) x_max <- max(data$icer_high) * 1.1
  
  if(is.null(bar_width)) bar_width <- 0.5
  
  label_dist <- (x_max - x_min) / 45  # Adjusted for better spacing
  
  plot<-ggplot(data, aes(x = fct_reorder(var_label, spread))) +    
    # Low estimate bars
    geom_rect(aes(xmin = as.numeric(fct_reorder(var_label, spread)) - bar_width, 
                  xmax = as.numeric(fct_reorder(var_label, spread)) + bar_width,
                  ymin = icer_low, ymax = EV, fill = low_label), 
              alpha = 1) +   
    # High estimate bars
    geom_rect(aes(xmin = as.numeric(fct_reorder(var_label, spread)) - bar_width,
                  xmax = as.numeric(fct_reorder(var_label, spread)) + bar_width,
                  ymin = EV, ymax = icer_high, fill = high_label), 
              alpha = 1) +
    # Basecase ICER and WTP threshold lines
    geom_hline(aes(yintercept = EV, linetype = "Basecase ICER"), color = "black", linewidth = 0.8) +
    # Labels for high and low values
    geom_text(aes(y = icer_high + label_dist, label = scales::dollar(icer_high, accuracy=1)), hjust = 0, color="grey30") +
    geom_text(aes(y = icer_low - label_dist, label = scales::dollar(icer_low, accuracy=1)), hjust = 1, color="grey30") +
    # Horizontal flip
    coord_cartesian(clip = "off")+
    coord_flip() +
    # Scaling and legend
    scale_fill_manual(values = impact_colors) +
    scale_linetype_manual(name=NULL,values = c("Basecase ICER" = "solid")) +
    scale_y_continuous(limits = c(x_min, x_max), breaks=x_breaks, minor_breaks = c(150000, 250000), labels = scales::dollar_format(prefix = "")) +
    scale_x_discrete(expand = expansion(mult = c(0.01, 0.01))) +
    # Labels and title
    labs(title = title, x = "", y = "Incremental Cost Effectiveness Ratio ($/QALY)", fill = "") +
    # Legend adjustments
    guides(fill = guide_legend(order = 1), linetype = guide_legend(order = 2)) +
    # Theme
    
    theme_minimal() +
    theme(
      panel.grid.major.y = element_blank() ,
      panel.grid.minor.y = element_blank(),
      legend.box = "vertical",
      legend.margin = margin(-10, 0, 0, 0),
      legend.key.height = unit(0.4, "cm"),
      legend.key.width = unit(0.8, "cm"),
      legend.title = element_text(size = 13),
      legend.text = element_text(size = 12),
      axis.line.x = element_line(color="black", size=0.4),
      axis.line.y = element_line(color="black", size=0.4),
      axis.ticks.x = element_line(color="black"),
      axis.text.y = element_text(size = 11, color="black"),
      axis.text.x = element_text(size = 11, color="black"),
      axis.title.x = element_text(size = 12, vjust=0.1),
      #axis.ticks.y = element_line(color="grey"),
      plot.title = element_text(size=12)
    )
  return(plot)
}

p<-plot_tornado(
  tornado_data |> filter(strat == "Risk Strat v NH"),
  title = "", x_min = 83000, x_max = 330000, bar_width=0.45, x_breaks=c(100000, 200000, 238725, 300000),
  ev_place=5
)
p
ggsave("owsa_plots/owsa_612b.png",  plot=p, width=10, height=4, units="in", bg="white", dpi=300)

ptop<-plot_tornado(
  tornado_data_top_ten |> filter(strat == "Risk Strat v NH"),
  title = "", x_min = 100000, x_max = 310000, bar_width=0.45, x_breaks=c(100000, 200000, 238725, 300000),
  ev_place=5
)
ptop
ggsave("owsa_plots/owsa_612_top10.png",  plot=ptop, width=10, height=4, units="in", bg="white", dpi=300)



