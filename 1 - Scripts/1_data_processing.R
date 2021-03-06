#******************************* CLEAN DATA & PROCESS VARIABLES ***************************#
#                                                                                          #
#                                                                                          #
#                                                                                          #
#******************************************************************************************#

# source here library for file management
library(here)

# source global options
source(here("global_options.R"))

# set working directory for data (not public)
setwd("~/Dropbox/CMU Survey/National analysis/0 - Aggregated data")

# load data
load("data_all.RData")

# set working directory
setwd(here("0 - Data"))

# ancillary files (zip to state + state codings)
z = read.csv("02_20_uszips.csv") %>% dplyr::select(zip, state_id)
states = read.csv("A3b-coding.csv")

# process data
e = d %>% mutate(
  # format date as date
  date = as.Date(StartDatetime, format = "%Y-%m-%d"),
  # add a unique ID
  #id = row_number(.),
  
  # format zip code as numeric
  zip = as.numeric(A3),
  
  # person-level fever
  fever = substring(B2,1,2)=="1,") %>%
  
  # get rid of colums
  dplyr::select(-StartDatetime, -EndDatetime) %>% 
  
  # join to zip codes
  left_join(z, "zip") %>%
  
  # join to state ID
  # state_abbv will now be the state abbreviation
  mutate(state_num = as.numeric(A3b)) %>%
  left_join(states,  c("state_num"="code"))

# filter for date  
e = e %>% filter(date>="2020-05-15" & date<="2020-11-22")
dim(e) # supplement

# label questions
names(e)[1:42] = c("HH_fever", "HH_sore_throat", "HH_cough", "HH_sob", "HH_diff_breathing",
                   "HH_n_sick", "HH_n", "zip_code", "state_rep", "com_n_sick", "symp", "symp_other", 
                   "symp_days", "taken_temp", "cough_mucus", "tested_covid", "hospital",
                   "conditions", "flu_shot", "work_outside_home", "hcw", "nursing_home",
                   "travel_outside_state", "avoid_contact", "anxious", "depressed", "worried_seriously_ill",
                   "work_contacts", "shopping_contacts", "social_contacts", "other_contacts", 
                   "contact_pos", "contact_pos_HH",
                   "gender", "gender_other", "pregnant", "age", "HH_u18", "HH_18_64", "HH_65_plus", "finances", 
                   "highest_temp")


#### CLEANING ####

# check that numeric variables were either left blank or
# that reasonable values were added
c = e %>% 
  # check if numeric answers were EITHER left blank 
  # OR 
  # a reasonable value was entered
  mutate(temp_chk = (is.na(highest_temp) | (highest_temp <= 104 & highest_temp > 97)),
         HH_chk = (is.na(HH_n_sick) | HH_n_sick <= 30) & (is.na(HH_n) | HH_n <= 30),
         n_sick_chk = (HH_n_sick <= HH_n) | is.na(HH_n_sick) | is.na(HH_n), 
         #com_chk = is.na(com_n_sick) | com_n_sick <= 100),
         work_chk = (is.na(work_contacts) | work_contacts < 100),
         social_chk = (is.na(social_contacts) | social_contacts < 100),
         shopping_chk = (is.na(shopping_contacts) | shopping_contacts < 100),
         other_chk = (is.na(other_contacts) | other_contacts < 100),
         all_chk = HH_chk & n_sick_chk & temp_chk & work_chk & social_chk & shopping_chk & other_chk,
         week = isoweek(date)) 

# summarize these
chk_outcomes = c %>% dplyr::summarize(temp = weighted.mean(temp_chk, weight = weight),
                                      HH = weighted.mean(HH_chk, weight = weight),
                                      work = weighted.mean(work_chk, weight = weight),
                                      social = weighted.mean(social_chk, weight = weight),
                                      shopping = weighted.mean(shopping_chk, weight = weight),
                                      other = weighted.mean(other_chk, weight = weight),
                                      all = weighted.mean(all_chk, weight = weight))

# subset on these
PROFANE_LANG = # We filtered out responses with profane or political language.
               # We don't want to upload to GitHub but are happy to share the list
               # or the cleaned file to researchers with microdata access
p = c %>% filter(all_chk) %>% 
  mutate(odd_symp = grepl(PROFANE_LANG, 
                          symp_other, ignore.case = T),
         all_symp = symp=="1,2,3,4,5,6,7,8,9,10,11,12,13,14",
         all_but_one_symp = symp=="1,2,3,4,5,6,7,8,9,10,11,12,13",
         all_and_odd = all_symp & odd_symp,
         have_symp1 = grepl("1,2", symp),
         have_symp2 = grepl("1,2", symp) & HH_fever==1,
         have_symp3 = grepl("1,2", symp) & !is.na(highest_temp),
         have_symp4 = grepl("1,2", symp) & (HH_fever==1 | !is.na(highest_temp)),
         taste = grepl("13", symp),
         symp_num = str_count(symp, ",")+1,
         HH_cough_aug = !(HH_cough=="2" | is.na(HH_cough)),
         HH_sob_aug = !(HH_sob=="2" | is.na(HH_sob)),
         HH_diff_breathing_aug = !(HH_diff_breathing=="2" | is.na(HH_diff_breathing)),
         cli = HH_fever=="1" & (HH_cough_aug | HH_sob_aug | HH_diff_breathing_aug),
         survey_chg = date>="2020-09-08") %>% 
  separate(symp, into = paste("var", 1:15, sep = ""), remove = F, sep = "\\,") 

p$cats = paste(ifelse(p$HH_fever==1, "A", ""), ifelse(p$HH_sore_throat==1, "B", ""), ifelse(p$HH_cough==1, "C", ""), ifelse(p$HH_sob==1, "D", ""), ifelse(p$HH_diff_breathing==1, "E", ""))
p$total = as.numeric(p$HH_fever==1) + as.numeric(p$HH_sore_throat==1) + as.numeric(p$HH_cough==1) + as.numeric(p$HH_sob==1) + as.numeric(p$HH_diff_breathing==1)
save(p, file = "~/Dropbox/CMU Survey/National analysis/0 - Aggregated data/tempfile.RData")

rm(c, d, z)
gc()

#### NEW VARIABLES ####

# make variables
q = p %>% filter(!all_symp & !all_but_one_symp & !odd_symp) %>% 
  filter(!is.na(state_id) & state_id!="PR") %>%
  mutate(
    any_work = ifelse(is.na(work_contacts),0, work_contacts),
    any_shopping = ifelse(is.na(shopping_contacts),0, shopping_contacts),
    any_social = ifelse(is.na(social_contacts),0, social_contacts),
    any_other = ifelse(is.na(other_contacts), 0, other_contacts),
    chk = !is.na(work_contacts) | !is.na(shopping_contacts) | !is.na(social_contacts) | !is.na(other_contacts),
    work_mod2 = ifelse(chk, any_work, NA),
    social_mod2 = ifelse(chk, any_social, NA),
    shopping_mod2 = ifelse(chk, any_shopping, NA),
    other_mod2 = ifelse(chk, any_other, NA),
    contacts_tot = work_mod2 + shopping_mod2 + social_mod2 + other_mod2,
    activities_masked_or_none = ifelse(is.na(C13), NA, C13==8 | (grepl("1", C13)==grepl("1", C13a) &
                                            grepl("2", C13)==grepl("2", C13a) & 
                                            grepl("4", C13)==grepl("4", C13a) &
                                            grepl("5", C13)==grepl("5", C13a) &
                                            grepl("6", C13)==grepl("6", C13a))),
    have_symp = grepl("1,2", symp),
    age_cat = ifelse(age>5, "65+", "45-64"),
    age_cat = ifelse(age<=3, "<45", age_cat),
    age_cat = factor(age_cat, levels = c("<45", "45-64", "65+")))

# function to aggregate dataset
make_vars = function(f){
  f = f %>% dplyr::summarize(date = max(date),
                              num = length(tested_covid),
                              
                              # avoid others 
                              avoid_peoplev2 = weighted.mean(ifelse(is.na(avoid_contact) & date<="2020-09-06", NA, avoid_contact<3), na.rm = T, w = weight),
                              avoid_people_num = sum(!is.na(avoid_contact) & date<="2020-09-06"),
                              
                              # worry
                              worried_sickv2 = weighted.mean(ifelse(is.na(worried_seriously_ill), NA, worried_seriously_ill==1), na.rm = T, w = weight),
                              worried_sick_num = sum(!is.na(worried_seriously_ill)),
                              
                              # activities masked or none
                              activities_masked_or_nonev2 = weighted.mean(ifelse(is.na(C13) & survey_chg, NA, activities_masked_or_none), w = weight, na.rm = T),
                              activities_masked_or_none_num = sum(!is.na(C13) & survey_chg),
                              
                              # contacts
                              contacts_avg_mod = weighted.mean(contacts_tot, na.rm = T, w = weight),
                              contacts_num = sum(chk),
                              
                              # missing data (weighted)
                              gender_missing = weighted.mean(is.na(gender), w = weight),
                              age_missing = weighted.mean(is.na(age), w = weight),
                              avoid_people_missing = weighted.mean(is.na(avoid_contact), w = weight),
                              contacts_missing = weighted.mean(!chk, w = weight),
                              worried_missing = weighted.mean(is.na(worried_seriously_ill), w = weight),
                              activities_missing = weighted.mean(is.na(C13), w = weight),
                              contacts_missing1 = weighted.mean(is.na(work_contacts), w = weight),
                              contacts_missing2 = weighted.mean(is.na(social_contacts), w = weight),
                              contacts_missing3 = weighted.mean(is.na(shopping_contacts), w = weight),
                              contacts_missing4 = weighted.mean(is.na(other_contacts), w = weight),
                              
                              # missing data (unweighted)
                              gender_missingT = mean(is.na(gender)),
                              age_missingT = mean(is.na(age)),
                              avoid_people_missingT = mean(is.na(avoid_contact)),
                              contacts_missingT = mean(!chk),
                              worried_missingT = mean(is.na(worried_seriously_ill)),
                              activities_missingT = mean(is.na(C13)),
                              contacts_missing1T = mean(is.na(work_contacts), na.rm = T),
                              contacts_missing2T = mean(is.na(social_contacts), na.rm = T),
                              contacts_missing3T = mean(is.na(shopping_contacts), na.rm = T),
                              contacts_missing4T = mean(is.na(other_contacts), na.rm = T),
                              
                              # gender
                              gender_avg = weighted.mean(gender==2, na.rm = T, w = weight),
                              gender_avg_total = mean(gender==2, na.rm = T),
                              
                              # gender
                              age = weighted.mean(age>=6, na.rm = T, w = weight),
                              age_total = mean(age>=6, na.rm = T),
                              
                              weight = sum(weight))
  return(f)
}

# aggregate by states and regions
load("state_cats.RData")
tic()
h = make_vars(q %>% group_by(week, state_id))  # state_coded
j = make_vars(q %>% group_by(week, region))
summer =  make_vars(q %>% filter(state_id%in%c(spring, summer)) %>% 
                      mutate(summer = state_id %in%summer) %>% group_by(week, summer))
fall =  make_vars(q %>% mutate(fall = state_id %in%(fall)) %>% group_by(week, fall))
i = make_vars(q %>% group_by(week))
toc()

# check aggregates
min(h$avoid_people_num[h$avoid_people_num>0])
min(h$worried_sick_num)
min(h$activities_masked_or_none_num[h$activities_masked_or_none_num>0])
min(h$contacts_num)

# save files
save(h, j, i, summer, fall, file = paste("summary_extract", Sys.Date(), ".RData", sep = ""))

# double-check counts                
i = p %>% filter(!all_symp & !all_but_one_symp & !odd_symp)
n = sum(h$num)

# estimates for supplement
(nrow(e)-nrow(i))
(nrow(e)-nrow(i))/nrow(e)

i2 = n
(nrow(i)-(i2))
(nrow(i)-(i2))/nrow(e)
(i2)/nrow(e)

#### Statistical Tests ####
load("state_cats.RData")
# Due to large sample size, these are fairly trivial.  Effect size is more important.
s = q %>% mutate(summer_val = state_id %in% summer,
                 pre = (date >= "2020-06-08" & date <= "2020-06-14")) %>% 
  filter(state_id %in% c(spring, summer)) %>%
  filter((date >= "2020-06-08" & date <= "2020-06-14") | (date >= "2020-07-13" & date <= "2020-07-19"))
summary(lm(avoid_contact~summer_val*pre, data = s, weights = weight))
summary(lm(contacts_tot~summer_val*pre, data = s, weights = weight))

r = q %>% mutate(fall = state_id %in% fall,
                 pre = (date >= "2020-09-14" & date <= "2020-09-20")) %>% 
  filter((date >= "2020-09-14" & date <= "2020-09-20") | (date >= "2020-11-16" & date <= "2020-11-22"))
summary(lm(activities_masked_or_none~pre*fall, data = r, weights = weight))
summary(lm(contacts_tot~pre*fall, data = r, weights = weight))

