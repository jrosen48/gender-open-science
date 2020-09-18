neededLibraries <- c("doBy", "ggplot2","plyr","reshape2", "xlsx")
lapply(neededLibraries, require, character.only = TRUE)

setwd("/Users/darko/Documents/Experiments/Active xProjects/GenderTitles (2018)/Data/5-Aggregate")

import <- read.table("gtAggregated_020918.csv", sep = ",", header=TRUE)
import$FullName <- paste(import$lastName,", ",import$firstName,sep="")

affiliationImport <- read.table("gtAggregatedAffiliations_042918.csv", sep = ",", header=TRUE)
affiliationImport$FullName <- paste(affiliationImport$lastName,", ",affiliationImport$firstName,sep="")

import$affiliation <- rep("None Extracted", nrow(import))

for(currentRecord in 1:nrow(import))
{
  print(currentRecord / nrow(import) * 100)
  seekingRecord <- import$pubmedRecord[currentRecord]
  seekingName <- import$FullName[currentRecord]
  
  foundRecord <- affiliationImport$affiliation[
    (affiliationImport$pubmedRecord == seekingRecord) &
    (affiliationImport$FullName == seekingName)]
  
  if(length(foundRecord) > 0)
  {
    import$Affiliation[currentRecord] <- toString(foundRecord)
  }
}

write.table(import, file = "gtAggregated_050118.csv", append = FALSE, sep = ",", row.name = FALSE, qmethod = "double")
