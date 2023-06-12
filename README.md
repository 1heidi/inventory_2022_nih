# inventory_2022_nih
Preliminary exploration of NIH repositories in the GBC Biodata Inventory
* using ePMC API via epmc package to test full text calls

* starting with the manually curated funders_geo_200.csv, which has article IDs as a list per individual agency extracted from ePMC metadata already

** extract all with NIH as known parent
** reshape to get dataframe with agency names separated for each article ID
*** = 1383 articles, some which will be duplicated b/c have multiple agencies 
** query article IDs via ePMC API to retrieve full text status (OA = Y) 
** filter to only OA = Y and deduplicate
*** == 534 unique articles 
** query article IDs via ePMC API to get XML for all articles
** parse and search for terms related to deposit capabilties
*** used upload* or deposit* as an example to test
** aggregate found terms for each article ID since some will have found multiple instances
** recombine with agency name from funders_geo_200.cs and biodata resource name from final_inventory_2022.csv

* output file: NIH_biodata_resources_text_mined_example_2023-06-12.csv