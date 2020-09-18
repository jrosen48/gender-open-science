#GENDER TITLES PROJECT
#Darko Odic & Erica Wojcik

# (2) IndexDivider: this script should be run second after IndexPubMadeSave. It takes existing RData files and "opens them" by looking into each publicataion and spliting it per author. It can also optionally get citations, which requires another pull from PubMed and takes time. It then outputs a CSV file with each author making up one line. MAKE SURE YOU SPECIFY THE CSV NAME FILE IN JOURNALINDEX.XLSX ONCE SAVED! After running this, run (3) NameProcessor to get the GenderStrings, and then (4) to graph any data, which is optional. 

#Version 1.0 (Feb/24/2016): Split this from the aggregator file in order to allow for easier processing of RData files. 

####################################################################################################################################

#Load libraries
neededLibraries <- c("RISmed","xlsx", "XML")
lapply(neededLibraries, require, character.only = TRUE)

#Set directory of R Scripts, but more importantly for loading JournalIndex
setwd("/Users/darko/Documents/Experiments/Active xProjects/GenderTitles (2018)/Processing") 
journalIndex <- read.xlsx('JournalIndex2018.xlsx', 1)
startIndex <- 96;
stopIndex <- 131;
journalIndex <- journalIndex[startIndex:stopIndex,]

#Set whether to get citations or not
getCitations <- FALSE;

#Get Timestamp so we know when aggregation happened
analysisTimestamp = Sys.time();
export = data.frame();
  
#This loop now takes those saved RData files and exports them in the appropriate format (one author per line)
for(currentIndex in 1:nrow(journalIndex))
{
  journalFullName <- journalIndex$Full.Journal.Name[currentIndex]
  journalAbbName <- journalIndex$Abbreviation[currentIndex]
  recordFile <- paste('../Data/1-RData/',journalIndex$Rdata.Saved[currentIndex], sep="")

  load(recordFile)
  print(as.character(recordFile))
  
  number.of.records <- length(ArticleTitle(records))
  
  #This process takes a long time depending on CPU speed and number of authors/paper
  for(currentRecord in 1:number.of.records)
  {
    #Basic Info
    pubmedRecord <- PMID(records)[currentRecord];
    title <- ArticleTitle(records)[currentRecord];
    journal <- Title(records)[currentRecord];
    year <- YearPubmed(records)[currentRecord];
    country <- Country(records)[currentRecord];
    
    #Output Progress
    #print(currentRecord/number.of.records*100)
    #print(pubmedRecord)

    #Optional: Getting citations requires going back to PubMed, which make this labourious and takes a long time. Note the getCitations variable above. 
    citations <- NA; 
    if(getCitations==TRUE)
    {
      #First Method: this method is built into RISMed but sometimes malfunctions. 
      search_topic <- paste(pubmedRecord,sep="")
      search_query <- EUtilsSummary(search_topic, retmax=1)
      citeRecord <- EUtilsGet(search_query) #this will take a while depending on number of records
      citations <- Cited(citeRecord)
      
      if(length(citations) == 0)
      {
        citations <- 0;
      }
      #Second Method: this method is still being worked on, but tries to solve the problem with Cited. DO NOT USE FOR NOW
      #test<-xmlToList(xmlParse("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?retmode=xml&dbfrom=pubmed&id=26539137"))
      #test3 <- as.data.frame(unlist(test$LinkSet))
      #citations<- length(which(test3$`unlist(test$LinkSet)`=="pubmed_pubmed_citedin"):which(test3$`unlist(test$LinkSet)`=="pubmed_pubmed_combined"))-3;
      #length(test$PubmedArticle$MedlineCitation$CommentsCorrectionsList)
    }
    
    #Check Author Number (because we'll repeat each row per author)
    authorList <- data.frame(Author(records)[currentRecord]);
    colnames(authorList) <- c("LastName","ForeName","Initials","order")
    
    affiliationList <- data.frame(Affiliation(records)[currentRecord]);
    colnames(affiliationList) <- c("Affiliation")
    
    totalAuthors <- nrow(authorList); 
    
    #This Loop goes author by author to divide into rows
    for(currentAuthor in 1:totalAuthors) #now we go author by author
    {
      author <- authorList[currentAuthor,]
      lastName <- author$LastName;
      firstName <- author$ForeName;
      order <- author$order;
      
      #Need to split the affiliation by the presence of the comma and identify only the one with the word UNIVERSITY
      affiliation <- affiliationList[currentAuthor,]
      splitAffiliation <- as.data.frame(strsplit(toString(affiliation),","))
      uniPosition <- which(grepl("Uni", splitAffiliation[,1], ignore.case = TRUE, useBytes = TRUE))
      
      officialAffiliation <- "None Extracted"
      if(length(uniPosition)>0)
      {
        officialAffiliation <- toString(splitAffiliation[uniPosition[1],1])
      }
      
      newLine <- data.frame(timestamp = analysisTimestamp,
                            pubmedRecord = pubmedRecord, 
                            lastName = lastName,
                            firstName = firstName,
                            authorOrder = order,
                            totalAuthors = totalAuthors,
                            affiliation = officialAffiliation,
                            pubTitle = title,
                            journal = journal,
                            year = year,
                            citations = citations,
                            country = country);
      export <- rbind(export,newLine);
    }
  }
  
  #CSV Output: MAKE SURE TO INPUT THE NAME INTO JOURNALINDEX ONCE DONE!
  fileName <- paste('../Data/99-Affiliation CSVs/gtAggAffiliation_',toString(journalAbbName),'_042518.csv', sep="")
  write.table(export, file = fileName, append = FALSE, sep = ",", row.name = FALSE, qmethod = "double")
  export = data.frame();
}

print("DONE DIVIDING!")