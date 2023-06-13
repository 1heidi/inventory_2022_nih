# inventory_2022_nih

## Preliminary exploration of NIH repositories in the GBC Biodata Inventory
### See associated repo: https://github.com/globalbiodata/inventory_2022

* **QUESTION: for biodata resources with NIH-associated agencies, can full-text queries help determine which offer deposit capabilities?** 

* make use of the [ePMC API](https://europepmc.org/RestfulWebService) and @rOpenSci's [europepmc](https://github.com/ropensci/europepmc) and [tidypmc](https://github.com/ropensci/tidypmc) packages and R's [tidyverse](https://github.com/tidyverse)

* start with "funders_geo_200.csv", which has article IDs listed for each individual agency as extracted from ePMC metadata and was manually curated to flag agencies associated with NIH, then:
  * filter to only those with NIH as known parent
  * reshape to get agency names separated for each article ID
    * = 1383 articles, some which will be duplicated b/c of multiple agencies/ID 
  * query article IDs via ePMC API to retrieve full text status (OA = Y) 
  * filter to only OA = Y and deduplicate
    * = 534 unique articles 
  * query those article IDs via ePMC API to get XML for all articles
  * parse and search for terms related to deposit capabilities
    * used upload* or deposit* as an example to test
  * aggregate found terms for each article ID since multiple terms can be found for each article
  * recombine with agency name from "funders_geo_200.csv" and with biodata resource "best name" from "final_inventory_2022.csv"

* **output file:** NIH_biodata_resources_text_mined_example_2023-06-13.csv -- **see "found_terms" variable**
