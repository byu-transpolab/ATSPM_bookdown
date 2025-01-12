
# Install tidyverse if needed
if (!require("tidyverse")) install.packages("tidyverse")

# Load tidyverse library
library(tidyverse)

# Read in PCD csv
PCD <- read_csv("data/PCD.csv") %>%
  select( -IsProtectedPhase, -TotalDelay, -ApproachId)

# Read in SF csv
SF <- read_csv("data/SplitFails.csv") %>%
  filter(IsProtectedPhase == "1") %>%
  select(-IsProtectedPhase, -GreenOccupancySum, -RedOccupancySum,
         -GreenTimeSum, -RedTimeSum, -ApproachId)
# Read in YR csv
YR <- read_csv("data/YellowRedActivations.csv") %>%
  filter(IsProtectedPhase == 1) %>%
  mutate(RVCycles = Cycles) %>%
  select(-IsProtectedPhase, -SevereRedLightViolations, -YellowActivations,
       -ViolationTime, -ApproachId, -Cycles)

## Read in BinStartTime csv
#BinStartTime <- read_csv("data/BinStartTimes_2020.csv", col_names = "DateTime") %>%
#  as_datetime()
# Had an issue with coercing it to be a dttm

# Create a BinStartTime from the PCD dataset
PCDBinStartTime <- PCD %>%
  select(BinStartTime)
PCDBinStartTime <- unique(PCDBinStartTime)

# Read in Signal ID csv  
SignalId <- read_csv("data/SignalId.csv")

# Create a Phase Number 2&6 tibble
PhaseNumber <- tibble(PhaseNumber = c(2,6))

base_tibble <-
    expand_grid(
      PCDBinStartTime,
      SignalId,
      PhaseNumber
    )
all_tibble <-
  base_tibble %>%
  left_join(PCD, by = c('BinStartTime', 'SignalId', 'PhaseNumber')) %>%
  left_join(SF, by = c('BinStartTime', 'SignalId', 'PhaseNumber')) %>%
  left_join(YR, by = c('BinStartTime', 'SignalId', 'PhaseNumber'))
