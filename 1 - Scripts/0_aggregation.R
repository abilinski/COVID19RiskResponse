#************************************* AGGREGATE DATA *************************************#
#                                                                                          #
#                                                                                          #
#                                                                                          #
#******************************************************************************************#

# library
library(tidyverse)

# set working directory
# This aggregates monthly microdata files produced by CMU from April through November.
setwd("~/Dropbox/CMU Survey/Data deduplicated/Monthly aggregates")
rm(list=ls())
files = data.frame(x = list.files()) %>% mutate(val = substring(x, 1, 25)) %>% filter(!grepl("gz", x)) %>%
  filter(grepl(".csv", x)) %>% group_by(val) %>% summarize(names = rev(x)[1])

# read in the data
d = data.frame()
for(i in 1:nrow(files)){
  d = bind_rows(d, read.csv(files$names[i]))
  print(i)
}

# set working directory to store data
setwd("~/Dropbox/CMU Survey/National analysis/0 - Aggregated data")

# save data
save(d, file = "data_all.RData")

