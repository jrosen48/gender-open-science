#Load libraries
neededLibraries <- c("doBy", "xlsx")
lapply(neededLibraries, require, character.only = TRUE)

#setwd("/Users/darko/Documents/Experiments/Active xProjects/GenderTitles (2015)/R Scripts/NameFiles/NA Names")
#setwd("/Users/darko/Documents/Experiments/Active xProjects/GenderTitles (2018)/Data/4-Classified CSVs") 
setwd("/Users/darko/Documents/Experiments/Active xProjects/GenderTitles (2018)/Data/99-Affiliation Classified") 
files <- list.files(pattern = "gtClassifiedAffiliation_")

export <- data.frame()

for(currentCSV in 1:length(files))
{
  recordTable <- read.csv(files[currentCSV])
  print(recordTable$journal[1])
  export <- rbind(export,recordTable)
}
  
#write.table(export, file = "NANames_030516.csv", append = TRUE, sep = ",", row.name = FALSE, qmethod = "double")
write.table(export, file = "../5-Aggregate/gtAggregatedAffiliations_042918.csv", append = FALSE, sep = ",", row.name = FALSE, qmethod = "double")
print("DONE!")

