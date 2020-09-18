#GENDER TITLES PROJECT
#Darko Odic & Erica Wojcik

# (1) IndexPubMedSave: this script should be run first for new journals. It pulls and saves the data on journals as specified in the JournalIndex file and saves it as RData for further processing so we do not overwhelm the servers. MAKE SURE YOU SPECIFY THE RDATA NAME FILE IN JOURNALINDEX.XLSX ONCE SAVED! After running this, run (2) Divider to split the records into one line per author and get citations, then (3) NameProcessor to get the GenderStrings, and then (4) to graph any data, which is optional. 

#Version 1.0 (Feb/24/2016): Split this from the aggregator file in order to allow for easier processing of RData files. 

####################################################################################################################################

#Load libraries
neededLibraries <- c("RISmed","xlsx")
lapply(neededLibraries, require, character.only = TRUE)

#Set directory of R Scripts, but more importantly for loading JournalIndex
# setwd("/Users/darko/Documents/Experiments/Active xProjects/GenderTitles (2018)/Processing") #change to the location of the file
journalIndex <- read.xlsx('JournalIndex2018.xlsx', 1)
startIndex <- 1; #which journal to start with
stopIndex <- 131; #which journal to end with
journalIndex <- subset(journalIndex, (ID>=startIndex)&(ID<=stopIndex))

#Get Timestamp so we know when aggregation happened
analysisTimestamp = Sys.time();
export = data.frame();

#Pubmed pull specifications
maxRecords = 20000; #limit of how many records to pull per journal, this number is likely to capture everything
startDate = 2003;
endDate = 2020;

#This loop pulls and saves RData files from PubMed. Ideally we do this first without executing the rest of the script so we have the files saved and can work with them without worrying about internet.
for(currentIndex in 1:nrow(journalIndex))
{
  journalFullName <- journalIndex$Full.Journal.Name[currentIndex]
  journalAbbName <- journalIndex$Abbreviation[currentIndex]
  search_topic <- journalIndex$PubMed.Search.Term[currentIndex]
  
  search_query <- EUtilsSummary(search_topic, retmax=maxRecords, mindate=startDate,maxdate=endDate) 
  records <- EUtilsGet(search_query) #this will take a while depending on number of records
  
  #Saves RData Output: MAKE SURE YOU INPUT NAME INTO JOURNALINDEX ONCE DONE!
  fileName <- paste("../Data/1-RData/", toString(journalAbbName),'_Records_2017.RData', sep="")
  save(records, file = fileName)
  
  #Prints progress and number of records pulled. 
  print(journalFullName)
  print(currentIndex/nrow(journalIndex)*100)
  print(length(ArticleTitle(records)))
}

print("DONE WITH PUBMED SAVE!")