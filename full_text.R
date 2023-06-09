## Purpose: Verify inventory articles with full text available in Europe PMC
## Parts: 
## Package(s): europepmc, tidyverse, xml2
## Input file(s): 
## Output file(s): 

library(europepmc)
library(tidypmc)
library(tidyverse)
library(xml2)
library(tidytext)

##===========================================##
####### PART 1: Get IDs ready for query ####### 
##===========================================##

funders <- read.csv("funders_geo_200.csv")
nih <- filter(funders, known_parent == "NIH")

## get all IDs
nih2 <- separate(nih, 'associated_PMIDs', paste("ID", 1:600, sep="_"), sep=",", extra="drop")
nih2 <- nih2[,colSums(is.na(nih2))<nrow(nih2)]
nih2 <- select(nih2, -1, -2, -3, -5, -6, -7, -263)

nih3 <- nih2 %>%  pivot_longer(
    cols = starts_with("ID"),
    names_to = "ID",
    values_to = "pmid",
    values_drop_na = TRUE
  )

##===========================================================##
####### PART 2: Query if each article for OA and PMC ID ####### 
##===========================================================##

id_list <- nih3$pmid
id_list <- trimws(as.numeric(id_list))

y  <- NULL;
for (i in id_list) {
  r <- sapply(i, epmc_details) 
  pmid <- r[[1]]["pmid"]
  pmcid <- tryCatch(r[[1]]["pmcid"], error = function(cond) {
    message(paste("pmcid issue"))
    message(cond, sep="\n")
    return(NA)
    force(do.next)})
  oa <- r[[1]]["isOpenAccess"]
  report <- cbind(pmid, pmcid, oa)
  y <- rbind(y, report)
}

nih3$pmid <- trimws(as.numeric(nih3$pmid))

nih4 <- left_join(nih3, y, by="pmid")
nih4 <- unique(nih4)

nih5 <- filter(nih4, isOpenAccess == "Y") ## note articles duplicated when >1 agency found

##================================================##
####### PART 3: Retrieve and Query Full Text ####### 
##================================================##
## from https://github.com/ropensci/tidypmc

##retreive ft
ft <- epmc_ftxt("PMC7145612")

## convert into table
txt <- pmc_text(ft)

## search table for term
found <- separate_text(txt, "verifiable")

### for all articles ....

id_ft <- unique(nih5$pmcid)

test <- head(id_ft)
test2 <- map(test, epmc_ftxt)

##======================================================##
####### PART 3: Retrieve Full Text for OA Articles ####### 
##======================================================##

### Save files ###

## write.csv(nih2,"nih2.csv", row.names = FALSE)