## Purpose: Retreive citations and MESH terms for database naming study
## Parts: 1) load packages and data, 2) define functions, 3) filter data and set-up for API, 4) retrieve citations and MESH terms, and 5) save files
## Input file(s): names_temp.csv
## Output file(s): 

##===========================================##
## PART 1: load packages and data ------------
##===========================================##

library(tidyverse)
library(janitor)
library(europepmc)
library(tidypmc)

names <- read.csv("names_temp.csv")
names_orin <- read.csv("names_temp.csv")

##===========================================##
## PART 2: define functions ------------------
##===========================================##

## This function 

setup_names <- function(my_data) {
  
  a <- my_data |> 
    select(1:8) |> 
    separate('ID', paste("ID", 1:((max(str_count(names$ID, ',')))+1), sep="_"), sep=",", extra="drop") |> 
    remove_empty(which = c("rows", "cols")) |> ## just in case
    mutate(across(where(is.character), str_trim))
  
  return(a)
  
}

##=====================================================##
## PART 3: filter data and setup for API call -----------
##=====================================================##

names <- setup_names(names)
names <- select(names, 1, 15:21)

##=====================================================##
## PART 4: retrieve citations and MESH term -------------
##=====================================================##

id_list <- trimws(as.numeric(names$ID_1))

y  <- NULL;
for (i in id_list) {
  r <- sapply(i, epmc_details)
  ID_1 <- i
  pmid <- r[[1]]["pmid"]
  pub_year <- r[[1]]["pubYear"]
  mesh0 <- tryCatch(r[[6]]["descriptorName"], error = function(cond) {
    message(paste("mesh issue"))
    message(cond, sep="\n")
    return(data.frame(descriptorName = "no mesh terms"))
    force(do.next)}) ##accounts for no MESH headings
  mesh <- paste(shQuote(mesh0$descriptorName, type="sh"), collapse=", ") 
  cit_2023 <- r[[1]]["citedByCount"]
  if (is.null(pmid)) {report <- data.frame(ID_1 = i, pmid = NA, pubYear = NA, mesh = NA, citedByCount = NA)} else
  report <- cbind(ID_1, pmid, pub_year, mesh, cit_2023) ##accounts for failed PMIDs
  y <- rbind(y, report)
}

names <- y

names(names)[names(names) == "citedByCount"] <- "cit_2023"
names <- select(names, -2)
names_up <- names
names(names_up)[names(names_up) == "ID_1"] <- "ID"
names_updated <- left_join(names_up, names_orin, by = "ID")


##===============================##
## PART 5: Save files -------------
##===============================##

write.csv(names_updated, "final_inventory_data_resource_names_citations_MESH_2023-01-12.csv", row.names = FALSE)