# inventory_2022_nih

## Preliminary exploration of NIH repositories in the GBC Biodata Inventory
## See associated repo: https://github.com/globalbiodata/inventory_2022

### QUESTION: for biodata resources found in inventory with NIH-associated agencies (as found in article metadata) can full-text queries help determine which may be offer deposit capabilities? 

* starting with the manually curated "funders_geo_200.csv", which has article IDs as a list per individual agency as extracted from ePMC metadata already

  * extract all with NIH as known parent
  * reshape to get a dataframe with agency names separated for each article ID
    * = 1383 articles, some which will be duplicated b/c have multiple agencies 
  * query article IDs via ePMC API to retrieve full text status (OA = Y) 
  * filter to only OA = Y and deduplicate
    * = 534 unique articles 
  * query article IDs via ePMC API to get XML for all articles
  * parse and search for terms related to deposit capabilities
    * used upload* or deposit* as an example to test
  * aggregate found terms for each article ID since some found multiple
  * recombine with agency name from "funders_geo_200.csv"" and with biodata resource name from "final_inventory_2022.csv"

* output file: NIH_biodata_resources_text_mined_example_2023-06-12.csv
