# ============================================================
# BUILD MINIMUM COMPARABLE AREAS (MCA), BRAZIL 1940-2000
# ============================================================

library(sf)
library(dplyr)
library(purrr)
library(tidyr)
library(stringr)
library(igraph)
library(readr)
library(tibble)
library(ggplot2)

sf_use_s2(FALSE)

crs_work <- 5880

out_dir <- "data/processed/mca"

dir.create(
  out_dir,
  recursive = TRUE,
  showWarnings = FALSE
)


# ============================================================
# 1. Historical municipality files
# ============================================================

boundary_files <- c(
  `1940` = "data/raw/geobr_municipalities_data/municipalities_1940.gpkg",
  `1950` = "data/raw/geobr_municipalities_data/municipalities_1950.gpkg",
  `1960` = "data/raw/geobr_municipalities_data/municipalities_1960.gpkg",
  `1970` = "data/raw/geobr_municipalities_data/municipalities_1970.gpkg",
  `1980` = "data/raw/geobr_municipalities_data/municipalities_1980.gpkg",
  `1991` = "data/raw/geobr_municipalities_data/municipalities_1991.gpkg",
  `2000` = "data/raw/geobr_municipalities_data/municipalities_2000.gpkg"
)


file_check <- tibble(
  year = names(boundary_files),
  path = unname(boundary_files),
  exists = file.exists(boundary_files)
)

print(file_check)

if (any(!file_check$exists)) {
  stop(
    "Missing files:\n",
    paste(
      file_check$path[!file_check$exists],
      collapse = "\n"
    )
  )
}


# ============================================================
# 2. Read and standardize municipality maps
# ============================================================

read_municipality_map <- function(path, year) {

  message("Reading municipalities: ", year)

  x <- sf::st_read(
    path,
    quiet = TRUE
  )

  x <- sf::st_make_valid(x)

  x <- x[
    !sf::st_is_empty(x),
  ]

  x <- sf::st_transform(
    x,
    crs = crs_work
  )

  required_cols <- c(
    "code_muni",
    "name_muni"
  )

  missing_cols <- setdiff(
    required_cols,
    names(x)
  )

  if (length(missing_cols) > 0) {
    stop(
      paste0(
        "Missing columns in ",
        year,
        ": ",
        paste(
          missing_cols,
          collapse = ", "
        )
      )
    )
  }

  if (!"code_state" %in% names(x)) {
    x <- x |>
      dplyr::mutate(
        code_state = substr(
          as.character(code_muni),
          1,
          2
        )
      )
  }

  x <- x |>
    dplyr::mutate(
      year = as.integer(year),
      code_muni = as.character(code_muni),
      name_muni = as.character(name_muni),
      code_state = as.character(code_state),
      node_id = paste0(
        year,
        "_",
        code_muni
      )
    ) |>
    dplyr::select(
      year,
      code_muni,
      name_muni,
      code_state,
      node_id
    )

  return(x)
}


# ============================================================
# 3. Read all maps
# ============================================================

municipality_maps <- purrr::imap(
  boundary_files,
  ~ read_municipality_map(
    path = .x,
    year = .y
  )
)

years <- sort(
  as.integer(
    names(municipality_maps)
  )
)


# ============================================================
# 4. Municipality count diagnostics
# ============================================================

municipality_counts <- purrr::imap_dfr(
  municipality_maps,
  function(x, year_name) {

    tibble(
      year = as.integer(year_name),
      n_rows = nrow(x),
      n_codes = dplyr::n_distinct(x$code_muni),
      duplicate_codes =
        nrow(x) -
        dplyr::n_distinct(x$code_muni)
    )
  }
)

print(municipality_counts)

readr::write_csv(
  municipality_counts,
  file.path(
    out_dir,
    "municipality_counts_by_year.csv"
  )
)

if (any(municipality_counts$duplicate_codes > 0)) {
  warning(
    "Some historical maps contain duplicate municipality codes."
  )
}


# ============================================================
# 5. Historically valid state/territory transitions
# ============================================================

allowed_state_changes <- tibble::tribble(
  ~old_state, ~new_state,

  # Rondônia
  "13", "11",
  "51", "11",

  # Roraima
  "13", "14",

  # Amapá
  "15", "16",

  # Brasília / Distrito Federal
  "52", "53",

  # Distrito Federal -> Guanabara
  "30", "34",

  # Guanabara -> Rio de Janeiro
  "34", "33",

  # Mato Grosso -> Mato Grosso do Sul
  "51", "50",

  # Goiás -> Tocantins
  "52", "17",

  # MG/ES disputed territory
  "99", "31",
  "99", "32",
  "31", "99",
  "32", "99"
)


valid_state_transition <- function(old_state, new_state) {

  old_state <- as.character(old_state)
  new_state <- as.character(new_state)

  same_state <- old_state == new_state

  transition_key <- paste(
    old_state,
    new_state,
    sep = "_"
  )

  allowed_keys <- paste(
    allowed_state_changes$old_state,
    allowed_state_changes$new_state,
    sep = "_"
  )

  same_state |
    transition_key %in% allowed_keys
}


# ============================================================
# 6. Create genealogy links
# ============================================================

create_links <- function(
    old_sf,
    new_sf,
    old_year,
    new_year,
    additional_parent_share = 0.20,
    dominant_min_share = 0.50,
    sliver_share = 0.005
) {

  message(
    "\nMatching ",
    old_year,
    " -> ",
    new_year
  )

  old <- old_sf |>
    dplyr::select(
      old_node = node_id,
      old_code = code_muni,
      old_name = name_muni,
      old_state = code_state
    )

  new <- new_sf |>
    dplyr::select(
      new_node = node_id,
      new_code = code_muni,
      new_name = name_muni,
      new_state = code_state
    )

  old_area <- as.numeric(
    sf::st_area(old)
  )

  new_area <- as.numeric(
    sf::st_area(new)
  )

  idx <- sf::st_intersects(
    old,
    new
  )

  candidate_pairs <- tibble(
    old_row = rep(
      seq_along(idx),
      lengths(idx)
    ),
    new_row = unlist(
      idx,
      use.names = FALSE
    )
  )

  if (nrow(candidate_pairs) == 0) {
    stop(
      "No intersections for ",
      old_year,
      " -> ",
      new_year
    )
  }

  overlaps <- purrr::map2_dfr(
    candidate_pairs$old_row,
    candidate_pairs$new_row,

    function(i, j) {

      inter <- suppressWarnings(
        sf::st_intersection(
          sf::st_geometry(
            old[i, ]
          ),
          sf::st_geometry(
            new[j, ]
          )
        )
      )

      if (length(inter) == 0) {
        return(NULL)
      }

      overlap_area <- sum(
        as.numeric(
          sf::st_area(inter)
        ),
        na.rm = TRUE
      )

      if (
        !is.finite(overlap_area) ||
        overlap_area <= 0
      ) {
        return(NULL)
      }

      tibble(
        old_row = i,
        new_row = j,
        overlap_area = overlap_area,
        share_old = overlap_area / old_area[i],
        share_new = overlap_area / new_area[j]
      )
    }
  )

  if (nrow(overlaps) == 0) {
    stop(
      "No positive-area overlaps for ",
      old_year,
      " -> ",
      new_year
    )
  }

  overlaps <- overlaps |>
    dplyr::mutate(
      old_node = old$old_node[old_row],
      new_node = new$new_node[new_row],
      old_code = old$old_code[old_row],
      new_code = new$new_code[new_row],
      old_name = old$old_name[old_row],
      new_name = new$new_name[new_row],
      old_state = old$old_state[old_row],
      new_state = new$new_state[new_row],
      old_year = as.integer(old_year),
      new_year = as.integer(new_year)
    )

  overlaps <- overlaps |>
    dplyr::filter(
      share_new >= sliver_share |
        share_old >= sliver_share
    )

  overlaps <- overlaps |>
    dplyr::mutate(
      state_transition_ok =
        valid_state_transition(
          old_state,
          new_state
        )
    ) |>
    dplyr::filter(
      state_transition_ok
    )

  if (nrow(overlaps) == 0) {
    stop(
      "No valid overlaps after state filter for ",
      old_year,
      " -> ",
      new_year
    )
  }

  overlaps <- overlaps |>
    dplyr::group_by(
      new_node
    ) |>
    dplyr::arrange(
      dplyr::desc(share_new),
      dplyr::desc(overlap_area),
      .by_group = TRUE
    ) |>
    dplyr::mutate(
      parent_rank = dplyr::row_number(),
      dominant_share = dplyr::first(share_new)
    ) |>
    dplyr::ungroup()

  links <- overlaps |>
    dplyr::filter(
      (
        parent_rank == 1 &
          dominant_share >= dominant_min_share
      ) |
        (
          parent_rank > 1 &
            share_new >= additional_parent_share
        )
    )

  low_dominant <- overlaps |>
    dplyr::filter(
      parent_rank == 1,
      dominant_share < dominant_min_share
    )

  if (nrow(low_dominant) > 0) {

    message(
      "   Dominant-parent share < ",
      dominant_min_share,
      ": ",
      nrow(low_dominant)
    )

    links <- dplyr::bind_rows(
      links,
      low_dominant
    ) |>
      dplyr::distinct(
        old_node,
        new_node,
        .keep_all = TRUE
      )
  }

  message(
    "   Valid candidate overlaps: ",
    nrow(overlaps)
  )

  message(
    "   Retained genealogy edges: ",
    nrow(links)
  )

  links |>
    dplyr::select(
      old_year,
      new_year,
      old_node,
      new_node,
      old_code,
      new_code,
      old_name,
      new_name,
      old_state,
      new_state,
      overlap_area,
      share_old,
      share_new,
      parent_rank,
      dominant_share
    )
}


# ============================================================
# 7. Build all historical transitions
# ============================================================

all_links <- purrr::map_dfr(
  seq_len(
    length(years) - 1
  ),
  function(i) {

    create_links(
      old_sf = municipality_maps[[
        as.character(years[i])
      ]],
      new_sf = municipality_maps[[
        as.character(years[i + 1])
      ]],
      old_year =
        years[i],
      new_year =
        years[i + 1],
      additional_parent_share = 0.20,
      dominant_min_share = 0.50,
      sliver_share = 0.005
    )
  }
)

readr::write_csv(
  all_links,
  file.path(
    out_dir,
    "municipality_genealogy_spatial_corrected.csv"
  )
)


# ============================================================
# 8. Transition diagnostics
# ============================================================

transition_diagnostics <- all_links |>
  dplyr::group_by(
    old_year,
    new_year
  ) |>
  dplyr::summarise(
    n_edges = dplyr::n(),
    median_share_new =
      median(
        share_new,
        na.rm = TRUE
      ),
    mean_share_new =
      mean(
        share_new,
        na.rm = TRUE
      ),
    min_share_new =
      min(
        share_new,
        na.rm = TRUE
      ),
    median_share_old =
      median(
        share_old,
        na.rm = TRUE
      ),
    .groups = "drop"
  )

print(
  transition_diagnostics
)

readr::write_csv(
  transition_diagnostics,
  file.path(
    out_dir,
    "transition_diagnostics.csv"
  )
)


# ============================================================
# 9. Parent diagnostics
# ============================================================

parent_counts <- all_links |>
  dplyr::count(
    new_year,
    new_node,
    name = "n_parents"
  )

print(
  parent_counts |>
    dplyr::count(
      new_year,
      n_parents
    )
)

multiple_parent_cases <- parent_counts |>
  dplyr::filter(
    n_parents > 2
  )

readr::write_csv(
  multiple_parent_cases,
  file.path(
    out_dir,
    "multiple_parent_cases.csv"
  )
)


# ============================================================
# 10. Create graph
# ============================================================

edges <- all_links |>
  dplyr::transmute(
    from = old_node,
    to = new_node
  ) |>
  dplyr::distinct()

all_nodes <- purrr::map_dfr(
  municipality_maps,
  function(z) {

    z |>
      sf::st_drop_geometry() |>
      dplyr::select(
        node_id,
        year,
        code_muni,
        name_muni,
        code_state
      )
  }
) |>
  dplyr::distinct(
    node_id,
    .keep_all = TRUE
  )

g <- igraph::graph_from_data_frame(
  d = edges,
  vertices = all_nodes,
  directed = FALSE
)

comp <- igraph::components(g)


# ============================================================
# 11. Node → graph component
# ============================================================

node_crosswalk <- tibble(
  node_id =
    names(
      comp$membership
    ),
  component =
    as.integer(
      comp$membership
    )
) |>
  dplyr::left_join(
    all_nodes,
    by = "node_id"
  )


# ============================================================
# 12. Identify components connected to 1940
# ============================================================

component_summary <- node_crosswalk |>
  dplyr::group_by(
    component
  ) |>
  dplyr::summarise(
    contains_1940 =
      any(year == 1940),
    contains_2000 =
      any(year == 2000),
    first_year =
      min(year),
    last_year =
      max(year),
    n_nodes =
      dplyr::n(),
    .groups = "drop"
  )

print(
  component_summary |>
    dplyr::count(
      contains_1940,
      contains_2000
    )
)

mca_components <- component_summary |>
  dplyr::filter(
    contains_1940
  )

node_crosswalk_mca <- node_crosswalk |>
  dplyr::semi_join(
    mca_components,
    by = "component"
  )


# ============================================================
# 13. Assign MCA IDs
# ============================================================

mca_ids <- node_crosswalk_mca |>
  dplyr::filter(
    year == 1940
  ) |>
  dplyr::arrange(
    code_state,
    code_muni
  ) |>
  dplyr::distinct(
    component
  ) |>
  dplyr::mutate(
    mca_id =
      sprintf(
        "MCA_%04d",
        dplyr::row_number()
      )
  )

node_crosswalk_mca <- node_crosswalk_mca |>
  dplyr::left_join(
    mca_ids,
    by = "component"
  )


# ============================================================
# 14. MCA count
# ============================================================

n_mca <- node_crosswalk_mca |>
  dplyr::distinct(
    mca_id
  ) |>
  dplyr::filter(
    !is.na(mca_id)
  ) |>
  nrow()

cat(
  "\n====================================\n"
)

cat(
  "Candidate MCA count: ",
  n_mca,
  "\n",
  sep = ""
)

cat(
  "Cavalcanti benchmark: 1275\n"
)

cat(
  "Difference from target: ",
  n_mca - 1275,
  "\n",
  sep = ""
)

cat(
  "====================================\n"
)


# ============================================================
# 15. Cross-state component diagnostics
# ============================================================

cross_state_components <- node_crosswalk_mca |>
  dplyr::filter(
    year == 2000
  ) |>
  dplyr::group_by(
    mca_id
  ) |>
  dplyr::summarise(
    n_states =
      dplyr::n_distinct(
        code_state
      ),
    states =
      paste(
        sort(
          unique(
            code_state
          )
        ),
        collapse = ", "
      ),
    n_municipalities =
      dplyr::n(),
    .groups = "drop"
  ) |>
  dplyr::filter(
    n_states > 1
  ) |>
  dplyr::arrange(
    dplyr::desc(n_states),
    dplyr::desc(n_municipalities)
  )

print(
  cross_state_components,
  n = Inf
)

readr::write_csv(
  cross_state_components,
  file.path(
    out_dir,
    "cross_state_components_corrected.csv"
  )
)


# ============================================================
# 16. Forbidden cross-state edges
# ============================================================

forbidden_cross_state_edges <- all_links |>
  dplyr::filter(
    old_state != new_state
  ) |>
  dplyr::mutate(
    transition_valid =
      valid_state_transition(
        old_state,
        new_state
      )
  ) |>
  dplyr::filter(
    !transition_valid
  )

cat(
  "\nForbidden cross-state edges remaining: ",
  nrow(
    forbidden_cross_state_edges
  ),
  "\n",
  sep = ""
)


# ============================================================
# 17. 2000 municipality → MCA crosswalk
# ============================================================

crosswalk_2000 <- node_crosswalk_mca |>
  dplyr::filter(
    year == 2000
  ) |>
  dplyr::select(
    code_muni,
    name_muni,
    code_state,
    mca_id,
    component
  ) |>
  dplyr::filter(
    !is.na(mca_id)
  ) |>
  dplyr::arrange(
    mca_id,
    code_muni
  )

cat(
  "\n2000 municipalities mapped: ",
  nrow(crosswalk_2000),
  "\n",
  sep = ""
)

cat(
  "Unique candidate MCAs: ",
  dplyr::n_distinct(
    crosswalk_2000$mca_id
  ),
  "\n",
  sep = ""
)

readr::write_csv(
  crosswalk_2000,
  file.path(
    out_dir,
    "municipality_2000_to_mca_1940_2000.csv"
  )
)


# ============================================================
# 18. Complete historical crosswalk
# ============================================================

crosswalk_all_years <- node_crosswalk_mca |>
  dplyr::filter(
    !is.na(mca_id)
  ) |>
  dplyr::select(
    year,
    code_muni,
    name_muni,
    code_state,
    mca_id,
    component
  ) |>
  dplyr::arrange(
    mca_id,
    year,
    code_muni
  )

readr::write_csv(
  crosswalk_all_years,
  file.path(
    out_dir,
    "municipality_to_mca_1940_2000.csv"
  )
)


# ============================================================
# 19. Identify unmatched 2000 municipalities
# ============================================================

muni_2000 <- municipality_maps[["2000"]]

muni_2000_mca <- muni_2000 |>
  dplyr::left_join(
    crosswalk_2000 |>
      dplyr::select(
        code_muni,
        mca_id
      ),
    by = "code_muni"
  )

unmatched_2000 <- muni_2000_mca |>
  dplyr::filter(
    is.na(mca_id)
  ) |>
  sf::st_drop_geometry()

print(
  unmatched_2000
)

readr::write_csv(
  unmatched_2000,
  file.path(
    out_dir,
    "unmatched_2000_municipalities.csv"
  )
)


# ============================================================
# 20. Build MCA polygons
# ============================================================

mca_1940_2000 <- muni_2000_mca |>
  dplyr::filter(
    !is.na(mca_id)
  ) |>
  dplyr::group_by(
    mca_id
  ) |>
  dplyr::summarise(
    .groups = "drop"
  ) |>
  sf::st_make_valid()

cat(
  "\nMCA polygon count: ",
  nrow(mca_1940_2000),
  "\n",
  sep = ""
)


# ============================================================
# 21. MCA geographic attributes
# ============================================================

mca_1940_2000$area_km2 <-
  as.numeric(
    sf::st_area(
      mca_1940_2000
    )
  ) /
  1e6

mca_points <- suppressWarnings(
  sf::st_point_on_surface(
    mca_1940_2000
  )
)

xy <- sf::st_coordinates(
  mca_points
)

mca_1940_2000$x <- xy[, "X"]
mca_1940_2000$y <- xy[, "Y"]

mca_points_ll <- sf::st_transform(
  mca_points,
  crs = 4326
)

ll <- sf::st_coordinates(
  mca_points_ll
)

mca_1940_2000$longitude <- ll[, "X"]
mca_1940_2000$latitude <- ll[, "Y"]


# ============================================================
# 22. Save MCA spatial files
# ============================================================

gpkg_path <- file.path(
  out_dir,
  "mca_1940_2000.gpkg"
)

rds_path <- file.path(
  out_dir,
  "mca_1940_2000.rds"
)

if (file.exists(gpkg_path)) {
  file.remove(gpkg_path)
}

sf::st_write(
  mca_1940_2000,
  dsn = gpkg_path,
  quiet = TRUE
)

saveRDS(
  mca_1940_2000,
  file = rds_path
)


# ============================================================
# 23. MCA group-size diagnostics
# ============================================================

mca_size <- crosswalk_2000 |>
  dplyr::count(
    mca_id,
    name = "n_municipalities_2000"
  ) |>
  dplyr::arrange(
    dplyr::desc(
      n_municipalities_2000
    )
  )

print(
  mca_size,
  n = 30
)

readr::write_csv(
  mca_size,
  file.path(
    out_dir,
    "mca_size_2000.csv"
  )
)


# ============================================================
# 24. State-specific MCA composition
# ============================================================

mca_state_size <- crosswalk_2000 |>
  dplyr::count(
    mca_id,
    code_state,
    name = "n_2000_municipalities"
  ) |>
  dplyr::arrange(
    dplyr::desc(
      n_2000_municipalities
    )
  )

print(
  mca_state_size,
  n = 50
)

readr::write_csv(
  mca_state_size,
  file.path(
    out_dir,
    "mca_state_size_2000.csv"
  )
)


# ============================================================
# 25. Plot candidate MCA geography
# ============================================================

mca_plot <- ggplot2::ggplot(
  mca_1940_2000
) +
  ggplot2::geom_sf(
    fill = "white",
    color = "grey30",
    linewidth = 0.15
  ) +
  ggplot2::theme_void() +
  ggplot2::labs(
    title = paste0(
      "Candidate Minimum Comparable Areas, 1940-2000 (n = ",
      nrow(mca_1940_2000),
      ")"
    )
  )

print(
  mca_plot
)


# ============================================================
# 26. Final validation report
# ============================================================

validation_report <- tibble::tibble(
  measure = c(
    "1940 municipalities",
    "2000 municipalities",
    "2000 municipalities mapped",
    "Unmatched 2000 municipalities",
    "Candidate MCAs",
    "Cavalcanti target MCAs",
    "Difference from target",
    "Cross-state candidate MCAs",
    "Forbidden cross-state edges"
  ),

  value = c(
    nrow(
      municipality_maps[["1940"]]
    ),

    nrow(
      municipality_maps[["2000"]]
    ),

    nrow(
      crosswalk_2000
    ),

    nrow(
      unmatched_2000
    ),

    n_mca,

    1275,

    n_mca - 1275,

    nrow(
      cross_state_components
    ),

    nrow(
      forbidden_cross_state_edges
    )
  )
)

print(
  validation_report
)

readr::write_csv(
  validation_report,
  file.path(
    out_dir,
    "mca_validation_report.csv"
  )
)
