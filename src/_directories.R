# Preamble ---------------------------------------------------------------------
#    Course Title:    Applied Econometrics Using GIS Techniques
#
#    Description:     This script defines the directory structure for the project and creates the necessary folders if they do not already exist.
#
#    Author:			    MD Redwan Hossin
#    E-mail:          redwanhossin.ju@gmail.com
#
#    Created: 	      2026-07-30
#    Last modified: 	2026-07-30
#    R version:	      4.5.2


# Define directory paths ------------------------------------------------
directories <- c(
  "code" = "R",
  "data_raw" = "data/raw",
  "data_external" = "data/external",
  "data_processed" = "data/processed",
  "data_gis" = "data/gis",
  "outputs_figures" = "outputs/figures",
  "outputs_images" = "outputs/images",
  "outputs_maps" = "outputs/maps",
  "outputs_tables" = "outputs/tables",
  "outputs_models" = "outputs/models",
  "docs" = "docs",
  "resources" = "resources",
  "src" = "src",
  "temp" = "temp"
)

# Create directories if they do not exist -----------------------------------
for (d in directories) {
  dir.create(here::here(d), recursive = TRUE, showWarnings = FALSE)
}

