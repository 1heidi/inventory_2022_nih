## Purpose: Search full text of NIH-assocaited inventory articles available as OA subset in Europe PMC
## Parts: 1) Get NIH-associated IDs,  2) Query to get PMC ID and if OA, 3) Retrieve XML and search for terms, and 4) Save output
## Package(s): europepmc, tidypmc, tidyverse
## Input file(s): funders_geo_200.csv, final_inventory_2022.csv
## Output file(s): NIH_biodata_resources_text_mined_example_2023-06-13.csv

library(europepmc)
library(tidypmc)
library(tidyverse)

##==========================================##
####### PART 1: Get NIH-associated IDs ####### 
##==========================================##

funders <- read.csv("funders_geo_200.csv")
nih <- filter(funders, known_parent == "NIH")

## get all IDs
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

##=================================================##
####### PART 2: Query to get PMC ID and if OA ####### 
##=================================================##

id_list <- nih3$pmid

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

nih4 <- left_join(nih3, y, by="pmid")
nih4 <- unique(nih4)
nih5 <- filter(nih4, isOpenAccess == "Y") ## note articles duplicated when >1 agency found

##=====================================================##
####### PART 3: Retrieve XML and search for terms ####### 
##=====================================================##

## get unique IDs
id_ft <- unique(nih5$pmcid)

## get full next and parse -- takes many minutes
x  <- NULL;
for (i in id_ft) {
  doc <- epmc_ftxt(i)
  m <- pmc_metadata(doc)
  pmcid <- m$PMCID
  doc2 <- pmc_text(doc)
  report <- cbind(pmcid, doc2)
  x <- rbind(x, report)
}

nih6 <- x

## search for terms indicating deposit capability per line
nih7 <- separate_text(nih6, ("upload*|deposit*"))

## aggregate for each PMCID
nih8 <- nih7 %>%
  group_by(pmcid) %>%
    mutate(found_terms = paste(unique(match), collapse = ', '))
nih9 <- unique(select(nih8, 2, 7))

## recombine with agency name

nih10 <- left_join(nih5, nih9, by = "pmcid")
nih10 <- select(nih10, 1, 3:6)

## recombine with biodata resource best name

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

## correct one wonky name
inv3$best_name[inv3$pmid == 34514416] <- "SCISSOR"

nih11 <- left_join(nih10, inv3, by = "pmid")
nih11 <- unique(nih11) ## have a few duplicates b/c

##==============================##
####### PART 4: Save files ####### 
##==============================##

write.csv(nih11,"NIH_biodata_resources_text_mined_example_2023-06-13.csv", row.names = FALSE)