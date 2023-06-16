## Purpose: Reshape inventory for unique PMID per row for checking alternate methods of identifying NIH funding
## Package(s): europepmc, tidyverse
## Input file(s): funders_geo_200.csv, final_inventory_2022.csv
## Output file(s): inventory_by_pmid_2023-06-16.csv

library(europepmc)
library(tidyverse)

##==========================================##
####### PART 1: Get All Inventory IDs ####### 
##==========================================##

inv <- read.csv("final_inventory_2022.csv")
inv <- select(inv, 1:2)
inv2 <- separate(inv, 'ID', paste("ID", 1:15, sep="_"), sep=",", extra="drop")
inv2 <- inv2[,colSums(is.na(inv2))<nrow(inv2)]

## reshape to get 1 ID per cell
inv3 <- inv2 %>%  pivot_longer(
  cols = starts_with("ID"),
  names_to = "ID",
  values_to = "pmid",
  values_drop_na = TRUE
)

inv3$pmid <- trimws(as.numeric(inv3$pmid))
inv3 <- select(inv3, 3, 1)
inv3$pmid <- trimws(as.numeric(inv3$pmid))

all_ids <- unique(select(inv3, 1))

##======================================================##
####### PART 2: Retrieve Article Metdata Requested ####### 
##======================================================##

t <- all_ids$pmid

y  <- NULL;
for (i in t) {
  r <- sapply(i, epmc_details) 
  id <- r[[1]]["id"]
  title <- r[[1]]["title"]
  authors <- r[[1]]["authorString"]
  abstract <- r[[1]]["abstractText"]
  report <- cbind(id, title, authors, abstract)
  y <- rbind(y, report)
}

all_m  <- y 

names(all_m)[1] <- "pmid"

##===========================================##
####### PART 3: Flag NIH-Associated IDs ####### 
##===========================================##

funders <- read.csv("funders_geo_200.csv")
nih <- filter(funders, known_parent == "NIH")

## get IDs
nih2 <- separate(nih, 'associated_PMIDs', paste("ID", 1:600, sep="_"), sep=",", extra="drop")
nih2 <- nih2[,colSums(is.na(nih2))<nrow(nih2)]
nih2 <- select(nih2, -1, -2, -3, -5, -6, -7, -263)

## reshape to get ID per cell
nih3 <- nih2 %>%  pivot_longer(
  cols = starts_with("ID"),
  names_to = "ID",
  values_to = "pmid",
  values_drop_na = TRUE
)

nih3$pmid <- trimws(as.numeric(nih3$pmid))
nih_ids <- select(nih3, 1, 3)

names(nih_ids)[1] <- "NIH_agency_found"

## combine dataframes

test <- left_join(all_m, nih_ids, by = "pmid")
test2 <- left_join(test, inv3, by = "pmid")
names(test2)[6] <- "biodata_resource_name"

write.csv(test2,"inventory_by_pmid_2023-06-16.csv", row.names = FALSE)


