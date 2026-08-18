library(geobr)

library(sf)

library(dplyr)

# Output folder

out_dir <- "data/raw/geobr_municipalities_data"

dir.create(

  out_dir,

  recursive = TRUE,

  showWarnings = FALSE

)

# Historical years

years <- c(1940, 1950, 1960, 1970, 1980, 1991, 2000)

# Download and save municipalities data 

for (y in years) {

  mun <- read_municipality(

    code_muni = "all",

    year = y

  )

  st_write(

    mun,

    file.path(out_dir, paste0("municipalities_", y, ".gpkg")),

    delete_dsn = TRUE,

    quiet = TRUE

  )

  cat(

    "Saved:", y,

    "| polygons:", nrow(mun),

    "\n"

  )

}