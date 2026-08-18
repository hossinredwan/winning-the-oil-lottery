# ============================================================
# BUILD MINIMUM COMPARABLE AREA (MCA) POLYGONS
# Cavalcanti et al. (2019) style
# ============================================================

pacman::p_load(
  sf,
  dplyr,
  haven,
  stringr
)

# ------------------------------------------------------------
# 1. Paths
# ------------------------------------------------------------

mun_path <- "data/raw/geobr_municipalities_data/municipalities_2000.gpkg"

crosswalk_dir <- "data/raw/crosswalks/municipality_to_mca/Ehrl_AMCgeneration_EE"

crosswalk_path <- file.path(
  crosswalk_dir,
  "_Crosswalk_1872_2010_final.dta"
)

out_dir <- "data/processed/mca"

dir.create(
  out_dir,
  recursive = TRUE,
  showWarnings = FALSE
)


# ------------------------------------------------------------
# 2. Read municipality geometry
# ------------------------------------------------------------

mun <- st_read(
  mun_path,
  quiet = TRUE
)

nrow(mun)
names(mun)
st_crs(mun)

# standardize 

mun <- mun |>
  mutate(
    code_muni = as.character(code_muni)
  )

# 3. Read the historical crosswalk 

cw <- read_dta(crosswalk_path)

cw <- cw |>
  mutate(
    code2010 = as.character(code2010)
  )

names(cw)
nrow(mca_crosswalk)

# filtering important variabeles 

cw_mca <- cw |>

  select(

    code2010,

    final_name,

    muname2000,

    clu2000_final,

    muname1991,

    clu1991_final,

    muname1980,

    clu1980_final,

    muname1970,

    clu1970_final,

    muname1960,

    clu1960_final,

    muname1950,

    clu1950_final,

    muname1940,

    clu1940_final,

    clu_final,

    amc

  )


cat(

  "1940 clusters:",

  n_distinct(cw_mca$clu1940_final),

  "\n"

)

cat(

  "1950 clusters:",

  n_distinct(cw_mca$clu1950_final),

  "\n"

)

cat(

  "1960 clusters:",

  n_distinct(cw_mca$clu1960_final),

  "\n"

)

cat(

  "1970 clusters:",

  n_distinct(cw_mca$clu1970_final),

  "\n"

)

cat(

  "1980 clusters:",

  n_distinct(cw_mca$clu1980_final),

  "\n"

)

cat(

  "1991 clusters:",

  n_distinct(cw_mca$clu1991_final),

  "\n"

)

cat(

  "2000 clusters:",

  n_distinct(cw_mca$clu2000_final),

  "\n"

)

cat(

  "Final AMC groups:",

  n_distinct(cw_mca$amc),

  "\n"

)

## 

geobr::read_comparable_areas(

  start_year = 1940,

  end_year = 2000,

  simplified = FALSE

)
#


# GitHub URL
url <- "https://github.com/ipea/geobr/raw/refs/heads/master/r-package/data/grid_state_correspondence_table.RData"

# Download to a temporary file
tmp <- tempfile(fileext = ".RData")

download.file(url, tmp, mode = "wb")

# Load the RData file
load(tmp)

# Check which object was loaded
ls()


head(tbl_df)
cw
dim(cw)
tail(cw)

cw$amc
