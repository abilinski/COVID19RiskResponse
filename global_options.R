#*********************************** GLOBAL OPTIONS ***************************************#
#                                                                                          #
#                                                                                          #
#******************************************************************************************#

#### KNITR GLOBAL OPTIONS ####
knitr::opts_chunk$set(echo = F, message = F, warning = F)

#### LIBRARIES ####
library(tidyverse)
library(lubridate) 
library(ISOweek)
library(knitr)
library(ggpubr)
library(here)
library(tictoc)
library(kableExtra)

# ggplot theme and color options
theme_opts = theme_minimal() + 
  theme(panel.border = element_blank(), panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), axis.line = element_line(colour = "black"))
  
pal = c("#457b9d", "#449187", "#52bdd3", "#a8ccb4")
col = "#0b2358"

# other options
size = 12
font = 3
lim = 8
