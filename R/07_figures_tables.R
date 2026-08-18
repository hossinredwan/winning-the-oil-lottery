# ============================================================
# Figure: Minimal Brazil map for presentation title slide
# ============================================================

library(sf)
library(ggplot2)

# Adjust this path to your processed MCA spatial file
mca_path <- file.path(
  "data",
  "processed",
  "spatial",
  "mca_1940_2000.rds"
)

if (!file.exists(mca_path)) {
  stop(
    "MCA spatial file not found: ", mca_path,
    "\nChange `mca_path` to the correct location."
  )
}

mca_sf <- readRDS(mca_path)

if (!inherits(mca_sf, "sf")) {
  stop("The object loaded from `mca_path` is not an sf object.")
}

# Remove invalid or empty geometries
mca_sf <- mca_sf[
  !sf::st_is_empty(mca_sf) &
    !is.na(sf::st_is_empty(mca_sf)),
]

mca_sf <- sf::st_make_valid(mca_sf)

# Create one national boundary
brazil_outline <- mca_sf |>
  sf::st_union() |>
  sf::st_as_sf()

title_map <- ggplot() +
  geom_sf(
    data = mca_sf,
    fill = "#F3F1EA",
    colour = "white",
    linewidth = 0.08
  ) +
  geom_sf(
    data = brazil_outline,
    fill = NA,
    colour = "#263238",
    linewidth = 0.7
  ) +
  coord_sf(
    datum = NA,
    expand = FALSE
  ) +
  theme_void() +
  theme(
    plot.background = element_rect(
      fill = "transparent",
      colour = NA
    ),
    panel.background = element_rect(
      fill = "transparent",
      colour = NA
    ),
    plot.margin = margin(2, 2, 2, 2)
  )

# Create presentation image directory if needed
dir.create(
  file.path("presentation", "images"),
  recursive = TRUE,
  showWarnings = FALSE
)

ggsave(
  filename = file.path(
    "presentation",
    "images",
    "brazil_title_map.png"
  ),
  plot = title_map,
  width = 6,
  height = 6,
  units = "in",
  dpi = 300,
  bg = "transparent"
)