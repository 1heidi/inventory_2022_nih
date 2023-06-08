## Purpose: Verify inventory articles with full text available in Europe PMC
## Parts: 1) retrieve records from query with full text and OA filter and then compare ID list with the IDs in the inventory
## Package(s): europepmc, tidyverse
## Input file(s): processed_manual_review.csv (temp! until final inventory file is available)
## Output file(s): inventory_FT_OA_ids_2022-11-21.csv

library(europepmc)
library(tidyverse)
  
## get IDs from inventory

all <- read.csv("funders_geo_200.csv")
inv <- inventory
inv <- separate(inv, 'ID', paste("ID", 1:30, sep="_"), sep=",", extra="drop")
inv <- inv[,colSums(is.na(inv))<nrow(inv)]
inv[, c(1:14)] <- sapply(inv[, c(1:14)],as.numeric)

ids <- select(inv, 1:14)
ids <- melt(ids, na.rm = TRUE, value.name = "ID")
id_list <- ids$ID
id_list <- as.data.frame(id_list)
names(id_list)[1] ="id"
id_list$id <- as.character(id_list$id)

same <- inner_join(id_list, oa_ft_list, keep = TRUE)
names(same)[1] ="inventory_ids"
names(same)[2] ="epmc_query_ids"

write.csv(same,"inventory_FT_OA_ids_2022-11-21.csv", row.names = FALSE)