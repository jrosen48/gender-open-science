#GENDER TITLES PROJECT
#Darko Odic & Erica Wojcik

# (3) IndexNameProcessor: this script should be run third for new journals. It pulls the names from the divided CSV and compares them to a file from the Open Gender Tracking project, assigning each name a "Male", "Female", "Unknown" (unisex), or "NA" (not inthe file). It also identifies titles with ? in them and the locatino of that character. MAKE SURE YOU SPECIFY THE CSV NAME FILE IN JOURNALINDEX.XLSX ONCE SAVED! After running this, run optionally (4) to graph any data, which is optional. 

#Version 1.0 (Feb/26/2016): Added comments

####################################################################################################################################

#Load libraries
neededLibraries <- c("doBy", "xlsx")
lapply(neededLibraries, require, character.only = TRUE)
#Sys.setlocale('LC_ALL','C') 

setwd("/Users/darko/Documents/Experiments/Active xProjects/GenderTitles (2018)/Processing") 
journalIndex <- read.xlsx('JournalIndex2018-Affiliations.xlsx', 1)
startIndex <- 1;
stopIndex <- 131;
journalIndex <- subset(journalIndex, (ID>=startIndex)&(ID<=stopIndex))

#Make Name Table
usNameTable <- read.table("Namebase/usprocessed.csv", header=TRUE, sep = ',')
ukNameTable <- read.table("Namebase/ukprocessed.csv", header=TRUE, sep = ',')
addNameTable <- read.table("Namebase/gt_additions.csv", header=TRUE, sep = ',')
nameTable <- rbind(usNameTable,ukNameTable, addNameTable)
nameTable <- nameTable[!duplicated(nameTable$Name),] #this combines US+UK removing the duplicates (adding about 6K names)

#We will change the percent threshold for deciding unisex names to 20-80 instead of 10-90
nameTable$prob.gender[nameTable$obs.male>=0.80] <- "Male"
nameTable$prob.gender[nameTable$obs.male<=0.20] <- "Female"

for(currentCSV in 1:nrow(journalIndex))
{
  export <- data.frame()
  filename <- paste('../Data/99-Affiliation Cleaned/',journalIndex$Clean.CSV.Saved[currentCSV], sep="")
  #filename <- as.character(journalIndex$Clean.CSV.Saved[currentCSV])
  recordTable <- read.csv(filename)
  print(filename)
  
  number.of.rows <- nrow(recordTable)
  
  GenderString <- rep(NA,number.of.rows)
  MalePercent <- rep(-1,number.of.rows)
  TitleQuestion <- rep(NA,number.of.rows)
  QuestionPosition <- rep(0,number.of.rows)
  PrimaryCategory <- rep(NA,number.of.rows)
  SecondaryCategory <- rep(NA,number.of.rows)
  
  for(currentRow in 1:number.of.rows)
  {
#    print(paste(journalIndex$Abbreviation[currentCSV],":",toString(currentRow/number.of.rows*100)))
    
    row <- recordTable[currentRow,]
    rowFirstName <- toString(row$firstName);
    rowTitle <- toString(row$pubTitle);
    
    #if there is a middle or second name, we have to cut it
    #if first split is 1 letter, take second
    if(nchar(unlist(strsplit(rowFirstName," "))[1])==1) rowFirstName <- unlist(strsplit(rowFirstName," "))[2]
    if(nchar(unlist(strsplit(rowFirstName," "))[1]) > 1) rowFirstName <- unlist(strsplit(rowFirstName," "))[1] 
  
    estGenderString <- nameTable$prob.gender[pmatch(rowFirstName, nameTable$Name)]
    if(length(estGenderString)==0) estGenderString <- NA;
    
    estMalePercent <- nameTable$est.male[pmatch(rowFirstName, nameTable$Name)]
    if(length(estMalePercent)==0) estMalePercent <- -1;
  
    GenderString[currentRow] <- toString(estGenderString);
    MalePercent[currentRow] <- estMalePercent;
    TitleQuestion[currentRow] <- grepl("\\?",rowTitle);
    if(TitleQuestion[currentRow] == TRUE) QuestionPosition[currentRow] <- regexpr("\\?",rowTitle)[1]/nchar(rowTitle);
    
    PrimaryCategory[currentRow] <- toString(journalIndex$Primary.Category[currentCSV])
    SecondaryCategory[currentRow] <- toString(journalIndex$Secondary.Category[currentCSV])
  }
  
  export <- recordTable;
  export$GenderString <- GenderString;
  export$MalePercent <- MalePercent;
  export$PrimaryCategory <- PrimaryCategory;
  export$SecondaryCategory <- SecondaryCategory;
  export$TitleQuestion <- TitleQuestion;
  export$QuestionPosition <- QuestionPosition;
  
  #Full Output (including NAs)
  filename<- paste('../Data/99-Affiliation Classified/gtClassifiedAffiliation_',toString(journalIndex$Abbreviation[currentCSV]),'_042918.csv', sep="")
  write.table(export, file = filename, append = FALSE, sep = ",", row.name = FALSE, qmethod = "double")
  
  #NA OUTPUT: For now we are also outputting NA names to get a list of them
  #export <- subset(export,is.na(export$MalePercent))
  #filename<- paste('gtNA_',toString(journalIndex$Abbreviation[currentCSV]),'_031016.csv', sep="")
  #write.table(export, file = filename, append = TRUE, sep = ",", row.name = FALSE, qmethod = "double")
}
print("DONE!")

