# ============================================================
# 04_oil_wells_sf.R
# Prepare ANP oil wells and assign onshore wells to MCA polygons
# Study period: 1940–2000
# ============================================================

library(sf)
library(dplyr)
library(here)
library(lubridate)


# ------------------------------------------------------------
# 1. Paths
# ------------------------------------------------------------

mca_path <- here(
  "data",
  "processed",
  "mca_1872_2010.rds"
)

wells_path <- here(
  "data",
  "raw",
  "anp",
  "well_shapefile",
  "POCO_TABELAO_08092023.shp"
)

wells_clean_path <- here(
  "data",
  "processed",
  "wells_1940_2000.rds"
)

onshore_mca_path <- here(
  "data",
  "processed",
  "wells_onshore_mca_1940_2000.rds"
)

unmatched_path <- here(
  "data",
  "processed",
  "wells_onshore_unmatched_1940_2000.rds"
)


# ------------------------------------------------------------
# 2. Check input files
# ------------------------------------------------------------

if (!file.exists(mca_path)) {
  stop("Missing MCA file: ", mca_path)
}

if (!file.exists(wells_path)) {
  stop("Missing wells shapefile: ", wells_path)
}


# ------------------------------------------------------------
# 3. Load data
# ------------------------------------------------------------

mca <- readRDS(mca_path)

wells <- st_read(
  wells_path,
  quiet = TRUE
)

message("Loaded MCA polygons: ", nrow(mca))
message("Loaded ANP wells: ", nrow(wells))


# ------------------------------------------------------------
# 4. Check CRS
# ------------------------------------------------------------

message("MCA CRS:")
print(st_crs(mca))

message("Wells CRS:")
print(st_crs(wells))

if (is.na(st_crs(mca))) {
  stop("MCA CRS is missing.")
}

if (is.na(st_crs(wells))) {
  stop("Well CRS is missing.")
}


# ------------------------------------------------------------
# 5. Parse drilling date
# ------------------------------------------------------------

wells <- wells %>%
  mutate(
    drilling_date = dmy_hm(INICIO),
    drilling_year = year(drilling_date)
  )

if (any(is.na(wells$drilling_year))) {
  warning(
    "Some drilling years could not be parsed: ",
    sum(is.na(wells$drilling_year))
  )
}

message(
  "Available drilling years: ",
  min(wells$drilling_year, na.rm = TRUE),
  "–",
  max(wells$drilling_year, na.rm = TRUE)
)


# ------------------------------------------------------------
# 6. Restrict to study period: 1940–2000
# ------------------------------------------------------------

wells_1940_2000 <- wells %>%
  filter(
    drilling_year >= 1940,
    drilling_year <= 2000
  )

message("All ANP wells: ", nrow(wells))
message(
  "Wells drilled 1940–2000: ",
  nrow(wells_1940_2000)
)


# ------------------------------------------------------------
# 7. Transform wells to MCA CRS
# ------------------------------------------------------------

wells_1940_2000 <- st_transform(
  wells_1940_2000,
  st_crs(mca)
)

stopifnot(
  st_crs(wells_1940_2000) == st_crs(mca)
)

message("Wells transformed to MCA CRS.")


# ------------------------------------------------------------
# 8. Basic geometry checks
# ------------------------------------------------------------

message("Well geometry type:")
print(
  st_geometry_type(
    wells_1940_2000,
    by_geometry = FALSE
  )
)

message("Wells bounding box:")
print(st_bbox(wells_1940_2000))

message("MCA bounding box:")
print(st_bbox(mca))

message(
  "Valid MCA geometries: ",
  sum(st_is_valid(mca)),
  " / ",
  nrow(mca)
)


# ------------------------------------------------------------
# 9. Check onshore / offshore counts
# ------------------------------------------------------------

location_counts <- wells_1940_2000 %>%
  st_drop_geometry() %>%
  count(
    TERRA_MAR,
    name = "n"
  )

print(location_counts)


# ------------------------------------------------------------
# 10. Split onshore and offshore wells
# ------------------------------------------------------------

wells_onshore <- wells_1940_2000 %>%
  filter(TERRA_MAR == "T")

wells_offshore <- wells_1940_2000 %>%
  filter(TERRA_MAR == "M")

message("Onshore wells: ", nrow(wells_onshore))
message("Offshore wells: ", nrow(wells_offshore))


# ------------------------------------------------------------
# 11. Assign onshore wells to MCA polygons
# ------------------------------------------------------------

wells_onshore_mca <- st_join(
  wells_onshore,
  mca %>%
    select(amc),
  join = st_within,
  left = TRUE
)


# ------------------------------------------------------------
# 12. Check assignment success
# ------------------------------------------------------------

assignment_check <- wells_onshore_mca %>%
  st_drop_geometry() %>%
  summarise(
    total_onshore = n(),
    assigned = sum(!is.na(amc)),
    unassigned = sum(is.na(amc)),
    assignment_rate = mean(!is.na(amc)) * 100
  )

print(assignment_check)


# ------------------------------------------------------------
# 13. Extract unmatched onshore wells
# ------------------------------------------------------------

unmatched_onshore <- wells_onshore_mca %>%
  filter(is.na(amc))

message(
  "Unmatched onshore wells: ",
  nrow(unmatched_onshore)
)

if (nrow(unmatched_onshore) > 0) {

  message("Example unmatched wells:")

  unmatched_onshore %>%
    st_drop_geometry() %>%
    select(
      POCO,
      ESTADO,
      BACIA,
      drilling_year,
      LAT_DD,
      LONG_DD
    ) %>%
    head(10) %>%
    print()
}


# ------------------------------------------------------------
# 14. Save outputs
# ------------------------------------------------------------

saveRDS(
  wells_1940_2000,
  wells_clean_path
)

saveRDS(
  wells_onshore_mca,
  onshore_mca_path
)

saveRDS(
  unmatched_onshore,
  unmatched_path
)

message("Saved cleaned wells: ", wells_clean_path)
message("Saved onshore MCA assignment: ", onshore_mca_path)
message("Saved unmatched wells: ", unmatched_path)


# ------------------------------------------------------------
# 15. Final summary
# ------------------------------------------------------------

message("--------------------------------------------------")
message("Oil well spatial preparation complete")
message("Study period: 1940–2000")
message("Total wells: ", nrow(wells_1940_2000))
message("Onshore wells: ", nrow(wells_onshore))
message("Offshore wells: ", nrow(wells_offshore))
message("Onshore assigned to MCA: ", assignment_check$assigned)
message("Onshore unassigned: ", assignment_check$unassigned)
message("--------------------------------------------------")

message(
  "NEXT: inspect unmatched onshore wells, then assign offshore wells ",
  "to nearest coastal MCA."
)

# ------------------------------------------------------------
# 16. Resolve unmatched onshore wells
# ------------------------------------------------------------

# Threshold for automatic nearest-MCA assignment
# 2 km safely includes the 12 small boundary/coastline mismatches
nearest_threshold_km <- 2

# Reproject for distance calculations
mca_proj <- st_transform(mca, 5880)
unmatched_proj <- st_transform(unmatched_onshore, 5880)

# Find nearest MCA
nearest_id <- st_nearest_feature(
  unmatched_proj,
  mca_proj
)

# Add nearest MCA and distance
unmatched_resolved <- unmatched_proj %>%
  mutate(
    nearest_amc = mca_proj$amc[nearest_id],

    distance_m = as.numeric(
      st_distance(
        unmatched_proj,
        mca_proj[nearest_id, ],
        by_element = TRUE
      )
    ),

    distance_km = distance_m / 1000,

    # Assign only small boundary mismatches
    amc = if_else(
      distance_km <= nearest_threshold_km,
      nearest_amc,
      NA_real_
    ),

    assignment_method = if_else(
      distance_km <= nearest_threshold_km,
      "nearest_boundary",
      "excluded_anomaly"
    )
  ) %>%

  # Return to MCA CRS
  st_transform(st_crs(mca))


# ------------------------------------------------------------
# 17. Mark wells already assigned by polygon
# ------------------------------------------------------------

onshore_within <- wells_onshore_mca %>%
  filter(!is.na(amc)) %>%
  mutate(
    assignment_method = "within",
    distance_km = 0
  )


# ------------------------------------------------------------
# 18. Combine finalized onshore wells
# ------------------------------------------------------------

wells_onshore_final <- bind_rows(
  onshore_within,
  unmatched_resolved
)


# ------------------------------------------------------------
# 19. Check final assignment
# ------------------------------------------------------------

onshore_final_check <- wells_onshore_final %>%
  st_drop_geometry() %>%
  count(
    assignment_method,
    name = "n"
  )

print(onshore_final_check)


# Summary
wells_onshore_final %>%
  st_drop_geometry() %>%
  summarise(
    total_onshore = n(),
    assigned = sum(!is.na(amc)),
    excluded = sum(is.na(amc))
  ) %>%
  print()


# ------------------------------------------------------------
# 20. Check excluded anomaly
# ------------------------------------------------------------

wells_onshore_final %>%
  filter(assignment_method == "excluded_anomaly") %>%
  st_drop_geometry() %>%
  select(
    POCO,
    ESTADO,
    BACIA,
    drilling_year,
    LAT_DD,
    LONG_DD,
    distance_km
  ) %>%
  print()


# ------------------------------------------------------------
# 21. Save finalized onshore dataset
# ------------------------------------------------------------

onshore_final_path <- here(
  "data",
  "processed",
  "wells_onshore_mca_final_1940_2000.rds"
)

saveRDS(
  wells_onshore_final,
  onshore_final_path
)

message(
  "Saved finalized onshore wells: ",
  onshore_final_path
)

# ------------------------------------------------------------
# 22. Identify coastal MCAs
# ------------------------------------------------------------

# Create a dissolved Brazil land boundary
brazil_union <- st_union(mca)

# Extract national coastline/boundary
brazil_boundary <- st_boundary(brazil_union)

# MCA polygons touching the national boundary
coastal_index <- lengths(
  st_intersects(
    mca,
    brazil_boundary
  )
) > 0

coastal_mca <- mca[coastal_index, ]

message("Coastal MCAs identified: ", nrow(coastal_mca))


# ------------------------------------------------------------
# 23. Project offshore wells and coastal MCAs
# ------------------------------------------------------------

# EPSG:5880 = SIRGAS 2000 / Brazil Polyconic
# Suitable for distance calculations across Brazil

offshore_proj <- st_transform(
  wells_offshore,
  5880
)

coastal_mca_proj <- st_transform(
  coastal_mca,
  5880
)


# ------------------------------------------------------------
# 24. Find nearest coastal MCA
# ------------------------------------------------------------

nearest_coastal_id <- st_nearest_feature(
  offshore_proj,
  coastal_mca_proj
)

offshore_mca <- offshore_proj %>%
  mutate(
    amc = coastal_mca_proj$amc[nearest_coastal_id]
  )


# ------------------------------------------------------------
# 25. Calculate distance to assigned coastal MCA
# ------------------------------------------------------------

offshore_mca <- offshore_mca %>%
  mutate(
    distance_m = as.numeric(
      st_distance(
        offshore_proj,
        coastal_mca_proj[nearest_coastal_id, ],
        by_element = TRUE
      )
    ),
    distance_km = distance_m / 1000,
    assignment_method = "nearest_coastal"
  )


# ------------------------------------------------------------
# 26. Return to common CRS
# ------------------------------------------------------------

offshore_mca <- st_transform(
  offshore_mca,
  st_crs(mca)
)


# ------------------------------------------------------------
# 27. Check offshore assignment
# ------------------------------------------------------------

offshore_check <- offshore_mca %>%
  st_drop_geometry() %>%
  summarise(
    total_offshore = n(),
    assigned = sum(!is.na(amc)),
    unassigned = sum(is.na(amc)),
    min_distance_km = min(distance_km),
    median_distance_km = median(distance_km),
    mean_distance_km = mean(distance_km),
    max_distance_km = max(distance_km)
  )

print(offshore_check)


# ------------------------------------------------------------
# 28. Inspect most distant offshore wells
# ------------------------------------------------------------

offshore_mca %>%
  st_drop_geometry() %>%
  select(
    POCO,
    ESTADO,
    BACIA,
    drilling_year,
    amc,
    distance_km
  ) %>%
  arrange(desc(distance_km)) %>%
  head(20) %>%
  print()


# ------------------------------------------------------------
# 29. Save offshore assignment
# ------------------------------------------------------------

offshore_output_path <- here(
  "data",
  "processed",
  "wells_offshore_mca_1940_2000.rds"
)

saveRDS(
  offshore_mca,
  offshore_output_path
)

message(
  "Saved offshore MCA assignment: ",
  offshore_output_path
)

# ------------------------------------------------------------
# 30. Final combination: onshore + offshore wells
# ------------------------------------------------------------

# Keep only successfully assigned onshore wells
onshore_assigned <- wells_onshore_final %>%
  filter(!is.na(amc))

# Offshore wells are already assigned to nearest coastal MCA
offshore_assigned <- offshore_mca %>%
  filter(!is.na(amc))

# Make sure both use the same CRS
onshore_assigned <- st_transform(
  onshore_assigned,
  st_crs(mca)
)

offshore_assigned <- st_transform(
  offshore_assigned,
  st_crs(mca)
)

stopifnot(
  st_crs(onshore_assigned) == st_crs(offshore_assigned)
)


# ------------------------------------------------------------
# 31. Standardize assignment variables
# ------------------------------------------------------------

onshore_assigned <- onshore_assigned %>%
  mutate(
    well_location = "onshore"
  )

offshore_assigned <- offshore_assigned %>%
  mutate(
    well_location = "offshore"
  )


# ------------------------------------------------------------
# 32. Combine all assigned wells
# ------------------------------------------------------------

wells_mca_final <- bind_rows(
  onshore_assigned,
  offshore_assigned
)


# ------------------------------------------------------------
# 33. Final checks
# ------------------------------------------------------------

final_check <- wells_mca_final %>%
  st_drop_geometry() %>%
  summarise(
    total_assigned = n(),
    onshore = sum(well_location == "onshore"),
    offshore = sum(well_location == "offshore"),
    missing_amc = sum(is.na(amc))
  )

print(final_check)


# Assignment method check
wells_mca_final %>%
  st_drop_geometry() %>%
  count(
    well_location,
    assignment_method,
    name = "n"
  ) %>%
  print()


# ------------------------------------------------------------
# 34. Check unique wells
# ------------------------------------------------------------

message(
  "Unique well IDs: ",
  n_distinct(wells_mca_final$POCO)
)

if (anyDuplicated(wells_mca_final$POCO) > 0) {
  warning("Duplicate POCO IDs found in final dataset.")
}


# ------------------------------------------------------------
# 35. Save excluded anomaly separately
# ------------------------------------------------------------

excluded_onshore <- wells_onshore_final %>%
  filter(is.na(amc))

excluded_path <- here(
  "data",
  "processed",
  "wells_excluded_spatial_anomaly_1940_2000.rds"
)

saveRDS(
  excluded_onshore,
  excluded_path
)


# ------------------------------------------------------------
# 36. Save final well → MCA dataset
# ------------------------------------------------------------

final_output_path <- here(
  "data",
  "processed",
  "wells_mca_1940_2000.rds"
)

saveRDS(
  wells_mca_final,
  final_output_path
)

message("Saved final well-MCA dataset: ", final_output_path)
message("Saved excluded anomaly: ", excluded_path)


# ------------------------------------------------------------
# 37. Final summary
# ------------------------------------------------------------

message("--------------------------------------------------")
message("FINAL WELL → MCA DATASET")
message("Study period: 1940–2000")
message("Original wells: ", nrow(wells_1940_2000))
message("Assigned wells: ", nrow(wells_mca_final))
message("Excluded spatial anomalies: ", nrow(excluded_onshore))
message("Distinct MCA with wells: ", n_distinct(wells_mca_final$amc))
message("--------------------------------------------------")

message(
  "NEXT: aggregate wells to MCA and construct ",
  "first drilling year, first discovery year, ",
  "treatment, and control indicators."
)

