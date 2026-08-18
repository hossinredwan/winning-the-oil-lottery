# ============================================================
# MCA 1940-2000
# Step 1: Load and standardize historical municipality maps
# ============================================================

library(sf)
library(dplyr)
library(purrr)
library(stringr)
library(tidyr)
library(igraph)
library(readr)

# Use planar GEOS operations because the analysis uses a projected CRS.
sf_use_s2(FALSE)

# EPSG:5880 (SIRGAS 2000 / Brazil Polyconic) provides one common projected
# coordinate system for comparing boundaries and calculating areas in Brazil.
crs_work <- 5880

out_dir <- "data/processed"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)


# ============================================================
# 1. Locate and check the historical boundary files
# ============================================================

# Names store census years; values store the corresponding GeoPackage paths.
boundary_files <- c(
  `1940` = "data/raw/geobr_municipalities_data/municipalities_1940.gpkg",
  `1950` = "data/raw/geobr_municipalities_data/municipalities_1950.gpkg",
  `1960` = "data/raw/geobr_municipalities_data/municipalities_1960.gpkg",
  `1970` = "data/raw/geobr_municipalities_data/municipalities_1970.gpkg",
  `1980` = "data/raw/geobr_municipalities_data/municipalities_1980.gpkg",
  `1991` = "data/raw/geobr_municipalities_data/municipalities_1991.gpkg",
  `2000` = "data/raw/geobr_municipalities_data/municipalities_2000.gpkg"
)

# Verify all inputs before beginning spatial processing.
file_check <- tibble(
  year = names(boundary_files),
  path = boundary_files,
  exists = file.exists(boundary_files)
)

print(file_check)

# Stop early and list any files that could not be found.
if (any(!file_check$exists)) {
  stop(
    "Missing municipality files: ",
    paste(file_check$path[!file_check$exists], collapse = ", ")
  )
}


# ============================================================
# 2. Read and standardize one census-year map
# ============================================================

# Returns an sf object with valid geometry, a common CRS, and common fields.
read_municipality_map <- function(path, year) {
  message("Reading municipalities: ", year)

  # Read quietly, repair invalid polygons, remove empty features, and transform
  # the map to the working CRS.
  x <- st_read(path, quiet = TRUE)
  x <- st_make_valid(x)
  x <- x[!st_is_empty(x), ]
  x <- st_transform(x, crs = crs_work)

  # Municipality code and name are required for all subsequent matching.
  required_cols <- c("code_muni", "name_muni")
  missing_cols <- setdiff(required_cols, names(x))

  if (length(missing_cols) > 0) {
    stop(
      paste0(
        "Missing columns in ", year, ": ",
        paste(missing_cols, collapse = ", "),
        "\nAvailable columns are:\n",
        paste(names(x), collapse = ", ")
      )
    )
  }

  # Municipality codes begin with Brazil's two-digit state code. Derive it
  # only for historical files that do not already provide code_state.
  if (!"code_state" %in% names(x)) {
    x <- x |>
      mutate(code_state = substr(as.character(code_muni), 1, 2))
  }

  # Harmonize field types and create an ID unique across years. select.sf()
  # retains the active spatial column automatically, regardless of its name.
  x |>
    mutate(
      year = as.integer(year),
      code_muni = as.character(code_muni),
      name_muni = as.character(name_muni),
      code_state = as.character(code_state),
      node_id = paste0(year, "_", code_muni)
    ) |>
    select(
      year,
      code_muni,
      name_muni,
      code_state,
      node_id
    )
}

# ============================================================
# 3. Load and combine all census years
# ============================================================

# A named list is retained so individual years remain easy to access, e.g.
# municipality_maps[["1940"]]. imap() passes each file path and its name/year.
municipality_maps <- imap(
  boundary_files,
  read_municipality_map
)

# Master sf dataset: one row per municipality-year observation.
x <- bind_rows(municipality_maps)

# Print a compact summary as a final verification.
print(x)

# ===============================================================
# 4. Function to create genealogy links 
# ===============================================================

create_links <- function(old_sf,
                         new_sf,
                         old_year,
                         new_year,
                         min_share = 0.05) {

  message(
    "Matching ",
    old_year,
    " -> ",
    new_year
  )

  # Keep minimal attributes
  old <- old_sf |>
    select(
      old_node = node_id,
      old_code = code_muni,
      old_name = name_muni
    )

  new <- new_sf |>
    select(
      new_node = node_id,
      new_code = code_muni,
      new_name = name_muni
    )

  # Candidate spatial intersections
  idx <- st_intersects(old, new)

  candidate_pairs <- tibble(
    old_row = rep(seq_along(idx), lengths(idx)),
    new_row = unlist(idx)
  )

  if (nrow(candidate_pairs) == 0) {
    return(tibble())
  }

  old_area <- as.numeric(st_area(old))
  new_area <- as.numeric(st_area(new))

  # Calculate actual overlap
  overlaps <- map2_dfr(
    candidate_pairs$old_row,
    candidate_pairs$new_row,
    function(i, j) {

      inter <- suppressWarnings(
        st_intersection(
          st_geometry(old[i, ]),
          st_geometry(new[j, ])
        )
      )

      if (length(inter) == 0) {
        return(NULL)
      }

      a <- sum(as.numeric(st_area(inter)))

      tibble(
        old_row = i,
        new_row = j,
        overlap_area = a,
        share_old = a / old_area[i],
        share_new = a / new_area[j]
      )
    }
  )

  # Candidate polygons can touch only at their boundaries, producing no
  # area-bearing intersections. Return an empty result in that case.
  if (nrow(overlaps) == 0) {
    return(tibble())
  }

  links <- overlaps |>
    filter(
      share_old >= min_share |
      share_new >= min_share
    ) |>
    mutate(
      old_year = old_year,
      new_year = new_year,
      old_node = old$old_node[old_row],
      new_node = new$new_node[new_row],
      old_code = old$old_code[old_row],
      new_code = new$new_code[new_row],
      old_name = old$old_name[old_row],
      new_name = new$new_name[new_row]
    ) |>
    select(
      old_year,
      new_year,
      old_node,
      new_node,
      old_code,
      new_code,
      old_name,
      new_name,
      overlap_area,
      share_old,
      share_new
    )

  links
}

# Names that begin with a number must be accessed with [[ ]] (or backticks).


years <- as.integer(names(municipality_maps))

all_links <- map_dfr(
  seq_len(length(years) - 1),
  function(i) {
    create_links(
      old_sf = municipality_maps[[i]],
      new_sf = municipality_maps[[i + 1]],
      old_year = years[i],
      new_year = years[i + 1],
      min_share = 0.05
    )
  }
)

# Save the genealogy table in the project's processed-data directory.
# recursive = TRUE creates parent directories if they do not yet exist.

write_csv(
  all_links,
  file.path(out_dir, "municipality_genealogy_spatial.csv")
)


========================================
# creating MCA graph approach 
========================================
========================================
all_links <- read_csv(
  "data/processed/municipality_genealogy_spatial.csv",
  show_col_types = FALSE
)
=======================================
edges <- all_links |>
  select(
    from = old_node,
    to = new_node
  ) |>
  distinct()

all_nodes <- map_dfr(
  municipality_maps,
  ~ st_drop_geometry(.x) |>
    select(
      node_id,
      year,
      code_muni,
      name_muni,
      code_state
    )
) |>
  distinct(node_id, .keep_all = TRUE)

g <- graph_from_data_frame(
  d = edges,
  vertices = all_nodes,
  directed = FALSE
)
comp <- components(g)

# Create_crosswalk 

node_crosswalk <- tibble(
  node_id = names(comp$membership),
  component = as.integer(comp$membership)
) |>
  left_join(
    all_nodes,
    by = "node_id"
  )

# Restrict MCA IDs to units representation in 1940

mca_components <- node_crosswalk |>
  group_by(component) |>
  summarise(
    contains_1940 = any(year == 1940),
    .groups = "drop"
  ) |>
  filter(contains_1940)

node_crosswalk <- node_crosswalk |>
  semi_join(
    mca_components,
    by = "component"
  )


mca_ids <- node_crosswalk |>
  filter(year == 1940) |>
  arrange(code_state, code_muni) |>
  distinct(component) |>
  mutate(
    mca_id = sprintf(
      "MCA_%04d",
      row_number()
    )
  )

node_crosswalk <- node_crosswalk |>
  left_join(
    mca_ids,
    by = "component"
  )

n_mca <- node_crosswalk |>
  distinct(mca_id) |>
  filter(!is.na(mca_id)) |>
  nrow()

n_mca


# Create the crucial 2000 municipality --> MCA crosswalk 

crosswalk_2000 <- node_crosswalk |>
  filter(year == 2000) |>
  select(
    code_muni,
    name_muni,
    code_state,
    mca_id,
    component
  ) |>
  arrange(mca_id, code_muni)

nrow(crosswalk_2000)

n_distinct(crosswalk_2000$mca_id)

write_csv(
  crosswalk_2000,
  file.path(out_dir, "municipality_2000_to_mca_1940_2000.csv")
)

# Create the full historical crosswalk

crosswalk_all_years <- node_crosswalk |>
  select(
    year,
    code_muni,
    name_muni,
    code_state,
    mca_id
  ) |>
  arrange(
    mca_id,
    year,
    code_muni
  )

write_csv(
  crosswalk_all_years,
  file.path(out_dir, "municipality_to_mca_1940_2000.csv")
)

# Build the MCA polygons 

muni_2000 <- municipality_maps[["2000"]]

muni_2000_mca <- muni_2000 |>
  left_join(
    crosswalk_2000 |>
      select(code_muni, mca_id),
    by = "code_muni"
  )

sum(is.na(muni_2000_mca$mca_id))

# get 1 missing mca , find out which one 

muni_2000_mca |>
  dplyr::filter(is.na(mca_id)) |>
  sf::st_drop_geometry()

recife_mca <- crosswalk_2000 |>
  dplyr::filter(
    code_state == "26",
    stringr::str_detect(name_muni, stringr::regex("^Recife$", ignore_case = TRUE))
  ) |>
  dplyr::pull(mca_id)

recife_mca

muni_2000_mca <- muni_2000_mca |>
  dplyr::mutate(
    mca_id = dplyr::if_else(
      code_muni == "2605459",
      recife_mca,
      mca_id
    )
  )

sum(is.na(muni_2000_mca$mca_id))

# desolve: 

mca_1940_2000 <- muni_2000_mca |>
  dplyr::filter(!is.na(mca_id)) |>
  dplyr::group_by(mca_id) |>
  dplyr::summarise(
    .groups = "drop"
  ) |>
  sf::st_make_valid()

nrow(mca_1940_2000)

# addiding mca attributes

mca_1940_2000 <- mca_1940_2000 |>
  dplyr::mutate(
    area_km2 = as.numeric(sf::st_area(mca_1940_2000)) / 1e6
  )

mca_points <- mca_1940_2000 |>
  sf::st_point_on_surface()

coords <- sf::st_coordinates(mca_points)

mca_1940_2000 <- mca_1940_2000 |>
  dplyr::mutate(
    x = coords[, "X"],
    y = coords[, "Y"]
  )

mca_ll <- mca_points |>
  st_transform(4326)

ll <- st_coordinates(mca_ll)

mca_1940_2000 <- mca_1940_2000 |>
  mutate(
    longitude = ll[, 1],
    latitude  = ll[, 2]
  )

st_write(
  mca_1940_2000,
  file.path(out_dir, "mca_1940_2000.gpkg"),
  delete_dsn = TRUE,
  quiet = TRUE
)

saveRDS(
  mca_1940_2000,
  file.path(out_dir, "mca_1940_2000.rds")
)

# plot
ggplot2::ggplot(mca_1940_2000) +
  ggplot2::geom_sf(
    fill = "white",
    color = "grey30",
    linewidth = 0.25
  ) +
  ggplot2::theme_void()

# validation using Rondonia test 

mca_size <- crosswalk_2000 |>
  count(
    mca_id,
    name = "n_municipalities_2000"
  ) |>
  arrange(desc(n_municipalities_2000))

mca_size

crosswalk_2000 |>
  count(
    mca_id,
    code_state,
    name = "n_2000_municipalities"
  ) |>
  arrange(desc(n_2000_municipalities)) |>
  print(n = 30)

# ============================================================
# Diagnostic 1: MCAs spanning multiple states
# ============================================================

cross_state_components <- node_crosswalk |>
  filter(year == 2000) |>
  group_by(mca_id) |>
  summarise(
    n_states = n_distinct(code_state),
    states = paste(
      sort(unique(code_state)),
      collapse = ", "
    ),
    n_municipalities = n(),
    .groups = "drop"
  ) |>
  filter(n_states > 1) |>
  arrange(desc(n_states), desc(n_municipalities))

cross_state_components

nrow(cross_state_components)

problem_components <- node_crosswalk |>
  filter(
    mca_id %in% cross_state_components$mca_id
  ) |>
  select(
    node_id,
    component,
    mca_id,
    year,
    code_state,
    code_muni,
    name_muni
  )

problem_components

node_info <- all_nodes |>
  select(
    node_id,
    year,
    code_state,
    code_muni,
    name_muni
  )

cross_state_edges <- all_links |>
  left_join(
    node_info |>
      rename(
        old_node = node_id,
        old_state = code_state,
        old_muni_name = name_muni
      ),
    by = "old_node"
  ) |>
  left_join(
    node_info |>
      rename(
        new_node = node_id,
        new_state = code_state,
        new_muni_name = name_muni
      ),
    by = "new_node"
  ) |>
  filter(
    old_state != new_state
  ) |>
  arrange(
    old_year,
    new_year,
    desc(overlap_area)
  )

cross_state_edges |>
  select(
    old_year,
    new_year,
    old_state,
    new_state,
    old_code,
    new_code,
    old_name,
    new_name,
    share_old,
    share_new
  ) |>
  print(n = 100)