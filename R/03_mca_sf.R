# ============================================================
# 03_mca_sf.R
# Build Minimum Comparable Area (MCA/AMC) polygons
# from IBGE municipality boundaries + Ehrl crosswalk
# ============================================================

library(sf)
library(dplyr)
library(purrr)
library(haven)
library(here)
library(ggplot2)

source(here::here("src", "_init.R"))


# ------------------------------------------------------------
# 1. Paths
# ------------------------------------------------------------

raw_crosswalk <- here(
  "data",
  "raw",
  "crosswalks",
  "municipality_to_mca",
  "Ehrl_AMCgeneration_EE",
  "_Crosswalk_1872_2010_final.dta"
)

raw_boundaries <- here(
  "data",
  "raw",
  "ibge_boundaries"
)

processed_gpkg <- here(
  "data",
  "processed",
  "mca_1872_2010.gpkg"
)

processed_rds <- here(
  "data",
  "processed",
  "mca_1872_2010.rds"
)

map_path <- here(
  "outputs",
  "images",
  "mca_polygons.png"
)


# ------------------------------------------------------------
# 2. Rebuild option
# ------------------------------------------------------------

# TRUE  = rebuild MCA from raw data
# FALSE = use existing processed file

force <- TRUE


# ------------------------------------------------------------
# 3. Check input files
# ------------------------------------------------------------

if (!file.exists(raw_crosswalk)) {
  stop("Missing crosswalk file: ", raw_crosswalk)
}

if (!dir.exists(raw_boundaries)) {
  stop("Missing IBGE boundary folder: ", raw_boundaries)
}


# ------------------------------------------------------------
# 4. Use existing MCA if available
# ------------------------------------------------------------

if (file.exists(processed_rds) && !force) {

  message("Using existing MCA file: ", processed_rds)

  mca_sf <- readRDS(processed_rds)

} else {

  # ----------------------------------------------------------
  # 5. Load municipality → MCA crosswalk
  # ----------------------------------------------------------

  cw <- read_dta(raw_crosswalk) %>%
    mutate(
      code2010 = as.character(code2010)
    )

  message("Crosswalk rows: ", nrow(cw))
  message("Distinct AMC values: ", n_distinct(cw$amc))


  # ----------------------------------------------------------
  # 6. Find municipality shapefiles
  # ----------------------------------------------------------

  shp_files <- list.files(
    raw_boundaries,
    pattern = "\\.shp$",
    recursive = TRUE,
    full.names = TRUE
  )

  if (length(shp_files) == 0) {
    stop("No shapefiles found in: ", raw_boundaries)
  }

  message("Municipality shapefiles found: ", length(shp_files))


  # ----------------------------------------------------------
  # 7. Read municipality shapefiles
  # ----------------------------------------------------------

  mun_list <- map(
    shp_files,
    ~ st_read(.x, quiet = TRUE)
  )


  # ----------------------------------------------------------
  # 8. Inspect source CRS
  # ----------------------------------------------------------

  source_crs <- map(mun_list, st_crs)

  message("Source municipality CRS values:")

  print(source_crs)


  # ----------------------------------------------------------
  # 9. Confirm all municipality files use same CRS
  # ----------------------------------------------------------

  epsg_values <- map_int(
    source_crs,
    function(x) {
      if (is.null(x$epsg) || is.na(x$epsg)) {
        NA_integer_
      } else {
        as.integer(x$epsg)
      }
    }
  )

  print(unique(epsg_values))

  if (all(is.na(epsg_values))) {
    message("No CRS metadata found in municipality shapefiles; assuming EPSG:4326.")
    mun_list <- map(mun_list, ~ st_set_crs(.x, 4326))
  } else if (length(unique(na.omit(epsg_values))) > 1) {
    stop(
      "Municipality shapefiles have different CRS values. ",
      "Do not combine until transformed to one CRS."
    )
  }


  # ----------------------------------------------------------
  # 10. Combine municipality polygons
  # ----------------------------------------------------------

  mun_2010 <- bind_rows(mun_list)

  if (is.na(st_crs(mun_2010)$epsg)) {
    st_crs(mun_2010) <- 4326
  }

  message("Municipality polygons: ", nrow(mun_2010))

  message("Combined municipality CRS:")
  print(st_crs(mun_2010))


  # ----------------------------------------------------------
  # 11. Municipality code
  # ----------------------------------------------------------

  if (!"GEOCODIGO" %in% names(mun_2010)) {
    stop("GEOCODIGO column not found in municipality boundaries.")
  }

  mun_2010 <- mun_2010 %>%
    mutate(
      code2010 = as.character(GEOCODIGO)
    )


  # ----------------------------------------------------------
  # 12. Join municipalities to MCA crosswalk
  # ----------------------------------------------------------

  mun_mca <- mun_2010 %>%
    left_join(
      cw %>%
        select(code2010, amc),
      by = "code2010"
    )

  message("Municipality rows: ", nrow(mun_mca))
  message("Missing AMC rows: ", sum(is.na(mun_mca$amc)))
  message(
    "Distinct matched AMC values: ",
    n_distinct(mun_mca$amc, na.rm = TRUE)
  )


  # ----------------------------------------------------------
  # 13. Aggregate municipality polygons to MCA
  # ----------------------------------------------------------

  mun_mca <- mun_mca %>%
    filter(!is.na(amc)) %>%
    mutate(geometry = st_make_valid(geometry))

  mca_sf <- mun_mca %>%
    group_by(amc) %>%
    summarise(
      geometry = st_union(geometry),
      .groups = "drop"
    )

  if (any(!st_is_valid(mca_sf))) {
    message("Repairing invalid MCA geometries...")
    mca_sf <- st_make_valid(mca_sf)
  }


  # ----------------------------------------------------------
  # 14. Validate MCA geometries
  # ----------------------------------------------------------

  message("MCA polygons: ", nrow(mca_sf))
  message(
    "Valid MCA geometries: ",
    sum(st_is_valid(mca_sf)),
    " / ",
    nrow(mca_sf)
  )

  message("MCA CRS:")
  print(st_crs(mca_sf))


  # ----------------------------------------------------------
  # 15. Save processed MCA
  # ----------------------------------------------------------

  dir.create(
    dirname(processed_rds),
    recursive = TRUE,
    showWarnings = FALSE
  )

  st_write(
    mca_sf,
    processed_gpkg,
    delete_dsn = TRUE,
    quiet = TRUE
  )

  saveRDS(
    mca_sf,
    processed_rds
  )

  message("Saved GeoPackage: ", processed_gpkg)
  message("Saved RDS: ", processed_rds)
}


# ------------------------------------------------------------
# 16. Final checks
# ------------------------------------------------------------

message("Final MCA rows: ", nrow(mca_sf))

message("Final MCA CRS:")
print(st_crs(mca_sf))

message("Final MCA bounding box:")
print(st_bbox(mca_sf))

message("Final geometry type:")
print(
  st_geometry_type(
    mca_sf,
    by_geometry = FALSE
  )
)


# ------------------------------------------------------------
# 17. Create MCA map
# ------------------------------------------------------------

dir.create(
  dirname(map_path),
  recursive = TRUE,
  showWarnings = FALSE
)

mca_map <- ggplot(mca_sf) +
  geom_sf(
    fill = "white",
    color = "grey30",
    linewidth = 0.15
  ) +
  theme_void() +
  labs(
    title = "Minimum Comparable Areas (AMC) — Brazil",
    subtitle = paste0(
      "Number of comparable areas: ",
      nrow(mca_sf)
    )
  )

print(mca_map)

ggsave(
  filename = map_path,
  plot = mca_map,
  width = 8,
  height = 6,
  dpi = 300,
  units = "in"
)

message("Saved map: ", map_path)