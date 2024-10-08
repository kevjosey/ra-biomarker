#############################################
## PURPOSD: Script for cleaning data       ##
##          in RA serum sample analysis    ##
## BY:      Kevin Josey                    ##
#############################################

require(plyr)
require(tidyverse)

## Data Cleaning
setwd("~/Dropbox/Projects/RA-Biomarker/")

raDat <- read.delim("data/forKevin.txt", stringsAsFactors = FALSE)
names(raDat) <- tolower(names(raDat))

raDat_case <- subset(raDat, diagnosis == "RA")
raDat_control <- subset(raDat, diagnosis == "Control")

serum_names <- names(raDat_case)[8:13]

raDat <- raDat[order(raDat$subj_id, raDat$sampnum),]
raDat <- raDat[complete.cases(raDat[,serum_names]),] # remove one observation missing 3 measurements

raDat$subj_id <- as.integer(factor(raDat$subj_id))

## Generate Data Frame for Table 1

# Getting age at diagnosis variable from age and t_years variables
tmp <- data.frame(agediag = raDat$age - raDat$t_yrs, subj_id = raDat$subj_id)
mean_agediag <- aggregate(agediag ~ subj_id, tmp, mean)
raDat <- join(raDat, mean_agediag, by = "subj_id", type = "left", match = "all")

# Deleting all but first observation per subject
raDat_t1 <- raDat[unique(raDat$subj_id),]

## Generate objects for data list to be passed to JAGS

# Outcome matrix
Y <- as.matrix( subset(raDat, select = serum_names) )
logY <- log(Y) # log transform responses

# Sample numbers
N <- nrow(Y) # number of samples
M <- nlevels(factor(raDat$subj_id)) # number of participants
K <- ncol(Y) # number of measurements per sample

# Covariates
time <- raDat$t_yrs # time before diagnosis
fem <- ifelse(raDat$gender == "F", 1, 0) # indeicator for female
nw <- ifelse(raDat$race_ethnic == "W", 0, 1) # indicator for non-white
famhx <- ifelse(raDat$familyhxra == "No", 0, 1)
bage.tmp <- raDat$agediag[unique(raDat$subj_id)]
bage <- rep(bage.tmp, times = table(raDat$subj_id))
diagnosis <- ifelse(raDat$diagnosis == "RA", 1, 0)

rm(tmp, mean_agediag, bage.tmp)

# ID vector
subj_id <- raDat$subj_id
study_id <- raDat$study_id

# Cleaned Data
clean <- data.frame(time, bage, fem, nw, famhx, subj_id, study_id, diagnosis, Y)
write.csv(clean, "data/clean.csv")
