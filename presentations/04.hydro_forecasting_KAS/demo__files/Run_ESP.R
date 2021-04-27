# run ESP forecast

install.packages("airGR") 
install.packages("dplyr")
install.packages("ggplot2")
install.packages("reshape2")
library(airGR)
library(dplyr)
library(ggplot2)
library(reshape2)

## SOME USEFUL FUNCTIONS

MakeDate <- function (day, month, year) {
  
  dateObject <- as.Date(paste(year, "-", month, "-", day, sep=""))
  return (dateObject)
  
}
RemoveLeapDay <- function (dateseries) {
  
  # Note: This function has been tested to work with date strings with/without
  #       a leap day present (i.e., 29th February)
  
  # Make sure date object
  dateseries <- as.Date(dateseries)
  
  # Find 29th Feb, if any
  leapDays <- which(format(dateseries, '%d') == "29" & format(dateseries, '%m') == "02")
  
  # If no leap days, retern series as input
  if (length(leapDays) == 0){
    
    return (dateseries)
    
  } else {
    
    # Remove all instances of 29th of Feb when it appears anywhere in dateseries
    dateeriesMinusLeap <- dateseries[-leapDays]
    
    # Return dateseries without 29th Feb
    return (dateeriesMinusLeap)
    
  }
  
}

dateFormat <- '%Y-%m-%d'

## GATHER DATA

# set station and its area
BasinInfoAll<-c(39019,234.1)
# Read BasinObs
BasinObs <- read.csv("./Final_New_BasinObs_1961_2017_39019.csv")
BasinObs$DATE <- as.POSIXct(BasinObs$DATE, format = dateFormat)
# Model parameters
Param <- c(455.6977636,-11.6614573,1085.473369,10.2877058)
# set data
DatesR    <- as.POSIXlt(BasinObs$DATE) # Get date in as.POSIXlt format
Precip    <- BasinObs$PRECIP 
PotEvap   <- BasinObs$PET
CatchArea <- BasinInfoAll[2]

## RUN GR4J FOR OBS PERIOD
InputsModel <- CreateInputsModel(FUN_MOD = RunModel_GR4J, DatesR = DatesR, 
                                 Precip = Precip, PotEvap = PotEvap)
Ind_Run <- seq(1:length(DatesR))
RunOptions <- suppressWarnings(CreateRunOptions(FUN_MOD = RunModel_GR4J,
                                                InputsModel = InputsModel, IndPeriod_Run = Ind_Run,
                                                IniStates = NULL, IniResLevels = NULL, 
                                                IndPeriod_WarmUp = NULL))
OutputsModel <- RunModel_GR4J(InputsModel = InputsModel,
                             RunOptions  = RunOptions,
                             Param       = Param)
obsSim<-as.data.frame(matrix(ncol=2,nrow=length(BasinObs$DATE),NA))
obsSim[,1]<-BasinObs$DATE
obsSim[,2]<-OutputsModel$Qsim
# Remove first 4 years as warm-up as change DATE to as.Date
colnames(obsSim) <- c("DATE", "obsSim")
obsSim$DATE<-as.Date(obsSim$DATE)
obsSim <- obsSim[which(obsSim$DATE > MakeDate(31,12,1964)), ]
# convert to cumecs
obsSim$obsSim <- (obsSim$obsSim * CatchArea) / 86.4
# merge with obs
obsSim$obs <- BasinObs$FLOW_cumecs[which(BasinObs$DATE==as.POSIXct(obsSim$DATE[1])):
                                     length(BasinObs$DATE)]

## MAKE A PLOT

ggplot(obsSim)+
  geom_line(aes(x=DATE,y=obsSim),color="cornflower blue")+
  geom_line(aes(x=DATE,y=obs), color="indianred")

## CREATE INPUT DATA FOR ESP
#remove the first few months to mirror start month of forecast
BasinObs <- read.csv("./Final_New_BasinObs_1961_2017_39019.csv")
BasinObs$DATE <- as.Date(BasinObs$DATE)
BasinObs<-BasinObs[which(BasinObs$DATE >= MakeDate(01,04,1961)),]

#remove leap years from BasinObs
NoLeap <- RemoveLeapDay(BasinObs$DATE)
BasinObsNoLeap <- as.data.frame(NoLeap)
colnames(BasinObsNoLeap)<-c("DATE")
BasinObsNoLeap <- left_join(BasinObsNoLeap, BasinObs, by = "DATE")

# Make input matrix for Precip 
PrecipESPin<-as.data.frame(matrix(NA,nrow=length(BasinObsNoLeap$DATE),ncol=(2021-1961)+1))
colnames(PrecipESPin)<-c("DATE",paste0("ENS",seq(1961,2020)))
PrecipESPin$DATE<-RemoveLeapDay(seq(MakeDate(01,04,1961),MakeDate(31,03,2021),by="day"))
PrecipESPin[1:length(BasinObsNoLeap$DATE),2:ncol(PrecipESPin)]<-BasinObsNoLeap$PRECIP
precipmatrix<-as.data.frame(matrix(BasinObsNoLeap$PRECIP,nrow=365,byrow=F))
colnames(precipmatrix)<-paste0("ENS",seq(1961,2020))
precipmatrix$DATE<-RemoveLeapDay(seq(MakeDate(01,04,2021),MakeDate(31,03,2022),by="day"))
PrecipESPin<-rbind(PrecipESPin,precipmatrix)
# Make input matrix for PET
PetESPin<-as.data.frame(matrix(NA,nrow=length(BasinObsNoLeap$DATE),ncol=(2021-1961)+1))
colnames(PetESPin)<-c("DATE",paste0("ENS",seq(1961,2020)))
PetESPin$DATE<-RemoveLeapDay(seq(MakeDate(01,04,1961),MakeDate(31,03,2021),by="day"))
PetESPin[1:length(BasinObsNoLeap$DATE),2:ncol(PetESPin)]<-BasinObsNoLeap$PET
petmatrix<-as.data.frame(matrix(BasinObsNoLeap$PET,nrow=365,byrow=F))
colnames(petmatrix)<-paste0("ENS",seq(1961,2020))
petmatrix$DATE<-RemoveLeapDay(seq(MakeDate(01,04,2021),MakeDate(31,03,2022),by="day"))
PetESPin<-rbind(PetESPin,petmatrix)
# Make an output matrix
ESPforecasts<-as.data.frame(matrix(NA,nrow=length(BasinObsNoLeap$DATE)+365,ncol=(2021-1961)+1))
colnames(ESPforecasts)<-c("DATE",paste0("ENS",seq(1961,2020)))
ESPforecasts$DATE<-RemoveLeapDay(seq(MakeDate(01,04,1961),MakeDate(31,03,2022),by="day"))

## RUN ESP
for (i in 2:61){
  DatesR    <- as.POSIXlt(ESPforecasts$DATE) # Get date in as.POSIXlt format
  Precip    <- PrecipESPin[,i] 
  PotEvap   <- PetESPin[,i]
  CatchArea <- BasinInfoAll[2]
    ## RUN GR4J FOR OBS PERIOD
  InputsModel <- CreateInputsModel(FUN_MOD = RunModel_GR4J, DatesR = DatesR, 
                                   Precip = Precip, PotEvap = PotEvap)
  Ind_Run <- seq(1:length(DatesR))
  
  RunOptions <- suppressWarnings(CreateRunOptions(FUN_MOD = RunModel_GR4J,
                                                  InputsModel = InputsModel, IndPeriod_Run = Ind_Run,
                                                  IniStates = NULL, IniResLevels = NULL, 
                                                  IndPeriod_WarmUp = NULL))
    OutputsModel <- RunModel_GR4J(InputsModel = InputsModel,
                                RunOptions  = RunOptions,
                                Param       = Param)
  ESPforecasts[,i]<-OutputsModel$Qsim
}

# convert runoff (mm/day) to flow (M3/s)
ESPforecasts_m3s <- ESPforecasts
ESPforecasts_m3s[,2:61] <- (ESPforecasts[2:61] * CatchArea) / 86.4

# MAKE A PLOT
ESPsub<-ESPforecasts_m3s[which(ESPforecasts$DATE>MakeDate(01,01,2021)),]
ESPmelt <- melt(ESPsub,id.var="DATE")
ggplot(ESPmelt,aes(x=DATE,y=value))+
  geom_line(aes(colour=variable))

