
## MCA Data : master file 

    1. mca_sf is a spatial dataset where each polygon represents one Minimum Comparable Area (MCA), created by merging municipalities that belong to the same historical comparable region.

    2. We rebuild it because the official MCA boundary shapefile is not publicly available, so we generate it ourselves using the IBGE municipality boundaries and the municipality→MCA crosswalk.

    3. This converts thousands of municipality polygons into a smaller set of stable MCA polygons that remain comparable despite municipal boundary changes over time (1872–2010).

    4. Later, we will assign oil wells, discoveries, and socioeconomic data (GDP, population, census variables) to these MCA polygons instead of individual municipalities.
    
    5. mca_sf becomes the master geographic layer for all GIS maps, spatial joins, and econometric analyses in the replication of the “Winning the Oil Lottery” paper.