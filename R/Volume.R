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
c <- b %>% mutate(Volume_hour = Volume*4,
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

#Left Join the Signals from Volume and from Signals_Unique
Signals_Unique <- left_join(Signal_List, Signals_Unique, by = 'SignalId')

#Left Join the Volume and Signals Unique csv for Corridor Names
Volume <- left_join(Volume, Signals_Unique, by = 'SignalId')


# Extract day from date
Volume <- mutate(Volume, day = lubridate::wday(BinStartTime))

# Filter just Tuesday, Wednesday and Thursday
Volume <- filter(Volume, day >= 3, day <= 5)

#Filter workable signals
Workable_Signals <- c(4024, 4090, 4704, 4705, 6303, 6304, 6307)
Volume <- filter(Volume, SignalId%in% Workable_Signals)


# Build the Pre-Covid df
Vol_PC <- filter(Volume, BinStartTime < "2020-03-12") #, BinStartTime > "2019-09-12")

# Build the Covid df
Vol_C <- filter(Volume, BinStartTime >= "2020-03-12")


#Graph Signal Specific Pre-COVID 19 Volumes
Volume%>%
  filter(
    timeperiod == "PMPeak",
    SignalId == 6303) %>%
  ggplot(aes(x= BinStartTime, y = Volume_hour, color = PhaseNumber)) +
  geom_point() #+
  #scale_colour_gradient(low="pink", high="dark green")
  #geom_smooth() +
  #geom_smooth(method = 'lm')

#Graph Signal Specific COVID-19 Volumes
Vol_C%>%
  filter(
    timeperiod == "PMPeak",
    SignalId == 4301,
    PhaseNumber ==2,) %>%
  ggplot(aes(x= BinStartTime, y = Volume_hour, color = hour)) +
  geom_point() #+
  #geom_smooth() +
  #geom_smooth(method = 'lm')


#Pick a month pre-covid to work with and get a mean volume for that signal, day, time period, and phase
#Feb11-Mar11 Pre-Covid, Mar12-Apr12 Covid, Oct13-Nov13 Flattened the Curve
  Vol_1 <- filter(Volume,
                  timeperiod == "PMPeak",
                  SignalId == 4301,
                  PhaseNumber ==2,
                  BinStartTime >= "2020-02-11",
                  BinStartTime < "2020-03-12")
  mean_vol1 <- mean(Vol_1$Volume_hour)
  sd_vol1 <- sd(Vol_1$Volume_hour)
  sample_size1 <- nrow(Vol_1)
  
  Vol_2 <- filter(Volume,
                  timeperiod == "PMPeak",
                  SignalId == 4301,
                  PhaseNumber ==2,
                  BinStartTime >= "2020-03-12",
                  BinStartTime < "2020-04-12")
  mean_vol2 <- mean(Vol_2$Volume_hour)
  sd_vol2 <- sd(Vol_2$Volume_hour)
  sample_size2 <- nrow(Vol_2)
  
  Vol_3 <- filter(Volume,
                  timeperiod == "PMPeak",
                  SignalId == 4301,
                  PhaseNumber ==2,
                  BinStartTime >= "2020-10-13",
                  BinStartTime < "2020-11-13")
  mean_vol3 <- mean(Vol_3$Volume_hour)
  sd_vol3 <- sd(Vol_3$Volume_hour)
  sample_size3 <- nrow(Vol_3)
  
  t.test(x, y, paired = TRUE, alternative = "two.sided")


#Pick two dates during covid, like when the shutdown happened and sometime after that and find the mean volume in there
#Pick a date well during COVID when something opened up and sometime after that and find the mean volume
#Get all of that into a csv or tibble or something and do a paired t test with it (Look back in Stat 201 notes)


#Get rid of outliers with for loop
#for (i in unique(Vol_PC$SignalId))
{
  Vol_PC %>%
    filter(SignalId == 4024)
  inner <- IQR(Vol_PC$Volume_hour)
  first_q <- quantile(Vol_PC$Volume_hour, prob=c(.25))
  third_q <- quantile(Vol_PC$Volume_hour, prob=c(.75))
  upper = third_q+inner
  lower = first_q+inner
  Vol_PC %>%
    filter(Volume_hour <= (upper), Volume_hour >= (lower))
  }
