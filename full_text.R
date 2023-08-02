## Purpose: Search full text of NIH-associated inventory articles available as OA subset in Europe PMC for terms suggesting potential deposit capabilities.
## Parts: 1a) load packages and data, 1b) define functions, 2a) filter data to NIH and isolate PMIDs, 2b) query to get PMC ID and if OA, 2c), retrieve XML and search for terms, 2d) join with biodata resource Best Name from GBC inventory, and 3) save files
## Input file(s): funders_geo_200.csv, final_inventory_2022.csv
## Output file(s): NIH_biodata_resources_text_mined_example_2023-08-01.csv

##===========================================##
## PART 1a: load packages and data ------------
##===========================================##

library(tidyverse)
library(janitor)
library(europepmc)
library(tidypmc)

funders <- read.csv("funders_geo_200.csv")
inv <- read.csv("final_inventory_2022.csv")

## correct a wonky name
inv$best_name[inv$pmid == 34514416] <- "SCISSOR"

##===========================================##
## PART 1b: define functions -------------------------
##===========================================##

## This function reshapes the data to have 1 PMID per row.

setup_nih <- function(my_data) {
  
  d <- my_data |> 
    filter(known_parent == "NIH") |> 
    separate('associated_PMIDs', paste("id", 1:((max(str_count(funders$associated_PMIDs, ',')))+1), sep="_"), sep=",", extra="drop") |> ## separate list of IDs into individual columns based on the max number of IDs via count of commas plus 1
    remove_empty(which = c("rows", "cols")) |> ## just in case
    select(-1, -2, -3, -5, -6, -7, -302) |> ## trim to just agency names and ids
    pivot_longer(
      cols = starts_with("id"),
      names_to = "id",
      values_to = "pmid",
      values_drop_na = TRUE
    ) |>
    mutate(across(where(is.character), str_trim))

    return(d)
  
}

## This function reshapes the data to have 1 PMID per row.

setup_inv <- function(my_data) {
  
  a <- my_data |> 
    select(1:2) |> 
    separate('ID', paste("ID", 1:((max(str_count(inv$ID, ',')))+1), sep="_"), sep=",", extra="drop") |> 
    remove_empty(which = c("rows", "cols")) |> ## just in case
    pivot_longer(
      cols = starts_with("id"),
      names_to = "id",
      values_to = "pmid",
      values_drop_na = TRUE
    ) |>
    mutate(across(where(is.character), str_trim))
  
    return(a)
  
}

##=============================================================##
## PART 2a: filter data to NIH and isolate PMIDs -----------------
##=============================================================##

nih <- setup_nih(funders)

##=======================================================##
## PART 2b: query to get PMC ID and if OA  -----------------
##=======================================================##

id_list <- trimws(as.numeric(nih$pmid))

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

nih_oa <- left_join(nih, y, by="pmid")
nih_oa <- unique(nih_oa) |>
  filter(isOpenAccess == "Y") ## note articles dup when >1 agency found

##=====================================================##
## PART 2c: retrieve XML and search for terms ------------ 
##=====================================================##

## get unique IDs - note must pass pmcids to API

id_ft <- unique(nih_oa$pmcid)

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

nih_oa_ft <- x

## search for terms indicating deposit capability per line
nih_terms <- separate_text(nih_oa_ft, ("upload*|deposit*"))

## aggregate terms for each PMCID
nih_terms <- nih_terms |>
  group_by(pmcid) |>
    mutate(found_terms = paste(unique(match), collapse = ', ')) |>
    select(2, 7) |>
    unique()

## recombine with agency name
nih_terms <- left_join(nih_oa, nih_terms, by = "pmcid")
nih_terms <- select(nih_terms, 1, 3, 6)

##===========================================================================##
## PART 2d: join with biodata resource Best Name from GBC inventory ----------- 
##===========================================================================##

inv <- setup_inv(inv)
inv <- select(inv, 3, 1)

nih_terms <- left_join(nih_terms, inv, by = "pmid")
nih_terms <- select(nih_terms, 1, 2, 4, 3) |>
             rename(best_name = best_name.x) |>
             unique()

##===========================================##
## PART 3: save files -------------------------
##===========================================##

write.csv(nih_terms, "NIH_biodata_resources_text_mined_example_2023-08-01.csv", row.names = FALSE)
