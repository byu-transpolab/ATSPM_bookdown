# Create Volume df
library(tidyverse)
library(lubridate)
library(data.table)

Volume_pre<- read_csv("data/TrafficVolume.csv")

vol <- Volume_pre %>%
  select(-Movement, -LaneNumber) %>% data.table()

b <- vol[, lapply(.SD, sum), by=list(BinStartTime, SignalId, ApproachId, PhaseNumber)] %>%
  as_tibble()

# Write Peak identifier    
c <- b %>% mutate(Volume_hour = Volume*4, #!!!adjust this so the volumes are combined into one observation!!!
                  hour = lubridate::hour(BinStartTime),
                  timeperiod = case_when(
                    hour >= 7 & hour <= 9 ~ "AMPeak",
                    hour >= 12 & hour <= 14 ~ "MidDay",
                    hour >= 16 & hour <= 18 ~ "PMPeak",
                    TRUE ~ "OffPeak"))
# Filter by Phase Number, only AM and PM Peaks, and after November 12/2017
d <- c %>% 
  filter(PhaseNumber%in% c(2,6), 
         timeperiod %in% c("AMPeak", "PMPeak"),
         BinStartTime >= "2017-11-12")

# Write rds file
write_rds(d, "data/Volume.rds")





# Start HERE unless rebuilding Volume file
library(tidyverse)
library(stats)
library(lubridate)

# Read Volume file in
Volume <- read_rds("data/Volume.rds")

# Make a list of Signals for reference
Signal_List <- c(unique(Volume$SignalId)) %>% 
  as.tibble() %>%
  rename(SignalId = value)

# Read in Signal Names csv
Signals_Unique <- read_csv("data/Signals_Joined_Unique.csv") %>%
  select(SignalId, StreetName, PrimaryName, SecondaryName)

# Left Join the Signals from Volume and from Signals_Unique
Signals_Unique <- left_join(Signal_List, Signals_Unique, by = 'SignalId')

# Left Join the Volume and Signals Unique csv for Corridor Names
Volume <- left_join(Volume, Signals_Unique, by = 'SignalId')

# Extract day from date
Volume <- mutate(Volume, 
                 day = lubridate::wday(BinStartTime), 
                 month = lubridate::month(BinStartTime),
                 COVID = if_else(BinStartTime > "2020-03-12",TRUE, FALSE))

# Filter after January 1, 2018
Volume <- filter(Volume, BinStartTime >= "2018-01-01")

# Filter just Tuesday, Wednesday and Thursday
Volume <- filter(Volume, day >= 3, day <= 5)

#Filter workable signals
Workable_Signals <- c(6303, 6304, 6307, 4024, 4090, 4704, 4705)
Volume <- filter(Volume, SignalId%in% Workable_Signals)

# Reorder columns to a more useful format
Volume_reg <- select(Volume,
                     BinStartTime, SignalId, day, month, Volume_hour, COVID,
                     PhaseNumber, hour, timeperiod, StreetName)

#Write .rds file
write_rds(Volume_reg, "data/Volume_reg.rds")



# Read in Volume dataset
Volume_reg <- read_rds("data/Volume_reg.rds")

# General Linear Regression Model
Vol_lm <- lm(Volume_hour ~ day + month + COVID + SignalId, data = Volume_reg)
summary(Vol_lm)

# Fixed Effects Model for month
Vol_fe_month <- lm(Volume_hour ~ factor(month), data = Volume_reg)
summary(Vol_fe_month)

# Fixed Effects Model for day
Vol_fe_day <- lm(Volume_hour ~ factor(day), data = Volume_reg)
summary(Vol_fe_day)

# Fixed Effects Model for COVID
Vol_fe_COVID <- lm(Volume_hour ~ factor(COVID), data = Volume_reg)
summary(Vol_fe_COVID)
