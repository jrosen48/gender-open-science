#GENDER TITLES PROJECT
#Darko Odic & Erica Wojcik

# (3) CleanTitles: this script should be run second after IndexDivider. It takes the cite or no-cite CSV files, reads them in, searches for any missing titles (usually due to symbols at start of name), any NA authors (usually from corrections), duplicate entries (usually our error), then reoutputs the files for name processing and merging.

#Version 3.0 (Mar/10/2016): Added function for removing names that are just initials
#Version 2.0 (Mar/1/2016): Added the removal of accents and dashes in the name. 
#Version 1.0 (Feb/29/2016): Made first version

####################################################################################################################################

#Load libraries
neededLibraries <- c("RISmed","xlsx", "XML", "RCurl")
lapply(neededLibraries, require, character.only = TRUE)

#Set directory of R Scripts, but more importantly for loading JournalIndex
setwd("/Users/darko/Documents/Experiments/Active xProjects/GenderTitles (2018)/Processing") 
journalIndex <- read.xlsx('JournalIndex2018-Affiliations.xlsx', 1)
accentList <- read.xlsx('Namebase/accentConversions.xlsx', 1)
startIndex <- 1;
stopIndex <- 131;
journalIndex <- journalIndex[startIndex:stopIndex,]

#Get Timestamp so we know when aggregation happened
analysisTimestamp = Sys.time();

for(currentCSV in 1:nrow(journalIndex))
{
  cleanTable = data.frame();
  filename <- paste('../Data/99-Affiliation CSVs/',journalIndex$CSV.Saved[currentCSV], sep="")
  print(journalIndex$CSV.Saved[currentCSV])
  recordTable <- read.csv(filename, header=TRUE)
  #recordTable <- read.table(filename, header=TRUE)
  recordTable$pubTitle <- as.character(recordTable$pubTitle)
  recordTable$firstName <- as.character(recordTable$firstName)

   ####################
  #(1) REMOVE DUPLICATED ROWS (ONLY FOR FULL ROW IDENTITY)
  ####################
  cleanTable <- recordTable[!duplicated(recordTable),]
  
  ####################
  #(2) REMOVE NA NAMES
  ####################
  cleanTable <- cleanTable[!is.na(cleanTable$lastName),] #NA last name
  cleanTable <- cleanTable[!is.na(cleanTable$firstName),] #NA first name
  
  ####################
  #(3) REPLACE MISSING TITLES
  #####################
  #This is the most intensive function because it requires us geting the Pubmed ID, then going to a specific website and pulling it from there. We first get the indices of all the NA titles, then process those (and only those) through the loop to save time
  na.title.index <- which(is.na(cleanTable$pubTitle)) #gives index of rows with missing title

  #for(currentIndex in 1:na.title.nrow)
  for(currentIndex in seq_along(na.title.index))
  {
    #print(currentIndex/na.title.nrow*100)#print progress
    
    pubmedID <- cleanTable$pubmedRecord[na.title.index[currentIndex]]
    
    #this address gets us to pubmed library in XML format, then we parse and pull 
    htmlAddress <- paste("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?retmode=xml&db=pubmed&id=", toString(pubmedID),sep="")
    xData <- getURL(htmlAddress)
    #xmlDownload <- xmlToList(xmlParse(htmlAddress))
    xmlDownload <- xmlToList(xmlParse(xData))
    articleTitle <- xmlDownload$PubmedArticle$MedlineCitation$Article$ArticleTitle
    
    if(is.null(articleTitle)) articleTitle <- xmlDownload$PubmedArticle$MedlineCitation$Article$VernacularTitle #special for AB
    
    cleanTable$pubTitle[na.title.index[currentIndex]] <- articleTitle
  }
  
  ####################
  #(4) ELIMINATE ACCENTS IN ROWS
  #####################
  #first we grab list of accents and their conversions (http://www.utf8-chartable.de/)
  for(currentAccent in 1:nrow(accentList))
  {
    cleanTable$firstName <- gsub(as.character(accentList$FieldCode[currentAccent]), as.character(accentList$Conversion[currentAccent]), cleanTable$firstName, fixed=TRUE)
    cleanTable$lastName <- gsub(as.character(accentList$FieldCode[currentAccent]), as.character(accentList$Conversion[currentAccent]), cleanTable$lastName, fixed=TRUE)
    cleanTable$affiliation <- gsub(as.character(accentList$FieldCode[currentAccent]), as.character(accentList$Conversion[currentAccent]), cleanTable$affiliation, fixed=TRUE)
  }
  
  ####################
  #(5) REMOVE DASHES IN NAMES
  #####################
  cleanTable$firstName <- gsub("-","",cleanTable$firstName);
  
  ####################
  #(6) REMOVE NAMES THAT ARE JUST INITIALS
  #####################
  for(i in 1:length(cleanTable$firstName))
  {
    #get total number of names (e.g., Peter L P = 3 names)
    nameNum <- length(unlist(strsplit(cleanTable$firstName[i]," "))); 
    
    #get number of names that have 1 letter (e.g., Peter L P = 2 initials)
    initialNum <- sum(nchar(unlist(strsplit(cleanTable$firstName[i]," ")))==1);
    
    #if all names are initials, remove them
    if(!is.na(initialNum))
    {
      if(nameNum == initialNum) cleanTable$firstName[i] <- NA;
    }
  }
  #get rid of all NA names
  cleanTable <- cleanTable[!is.na(cleanTable$firstName),] #NA first name
  
  #print(cleanTable$journal[1])
  #print(length(which(duplicated(cleanTable$pubTitle)==FALSE))) #get number of records post-clean (not rows)
  
  ####################
  #(7) EXPORT TO NEW FILE
  #####################
  filename<- paste('../Data/99-Affiliation Cleaned/gtAffiliationClean_',toString(journalIndex$Abbreviation[currentCSV]),'_042918.csv', sep="")
  write.table(cleanTable, file = filename, append = FALSE, sep = ",", row.name = FALSE, qmethod = "double")
}