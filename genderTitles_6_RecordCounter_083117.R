#GENDER TITLES PROJECT
#Darko Odic & Erica Wojcik
###############################################################################################################################
#Load libraries
neededLibraries <- c("doBy", "xlsx")
lapply(neededLibraries, require, character.only = TRUE)
#Sys.setlocale('LC_ALL','C') 

setwd("/Users/darko/Documents/Experiments/Active xProjects/GenderTitles (2018)/Processing")
journalIndex <- read.xlsx('JournalIndex2018.xlsx', 1)
startIndex <- 1;
stopIndex <- 131;
journalIndex <- subset(journalIndex, (ID>=startIndex)&(ID<=stopIndex))

export <- data.frame()

for(currentCSV in 1:nrow(journalIndex))
{
  filename <- paste('../Data/3-Cleaned CSVs/',journalIndex$Clean.CSV.Saved[currentCSV], sep="")
  recordTable <- read.csv(filename)

  recordTable$FullName <- paste(recordTable$lastName,", ",recordTable$firstName, sep="")
  
  number.of.rows <- nrow(recordTable)
  number.of.unique.titles <- length(unique(recordTable$pubTitle))
  number.of.unique.authors <- length(unique(recordTable$FullName))
  
  unique.titles.index <- c(unique(recordTable$pubTitle))
  citations.by.year <- summaryBy(citations~year,recordTable, FUN=c(mean))
  
  internalIF <- round(mean(citations.by.year$citations.mean[citations.by.year$year<2017]),2)
  
  print(paste(filename, ",", as.character(number.of.rows), ",", as.character(number.of.unique.titles), ",", as.character(number.of.unique.authors), ",", internalIF, sep=""))
  
  temp <- data.frame(filename, number.of.rows, number.of.unique.titles, number.of.unique.authors)
  export <- rbind(export, temp)
  
  #print(paste(filename, ",", internalIF, sep=""))
}
print("DONE!")

