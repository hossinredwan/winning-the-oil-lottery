# Preamble ---------------------------------------------------------------------
#    Course Title:    Applied Econometrics Using GIS Techniques
#
#    Description:     This script installs and loads all the R packages used in the project.
#
#    Author:			    MD Redwan Hossin
#    E-mail:          redwanhossian.ju@gmail.com
#
#    Created: 	      2026-07-30
#    Last modified: 	2026-07-30
#    R version:	      4.5.2

# Define package list ------------------------------------------------

## i. General Data Manipulation Libraries  
pkgs_dml = c(
"data.table",  # For fast data manipulation; also has some spatial capabilities, but not used here.
"tidyverse",   # For data manipulation and visualization; includes ggplot2, dplyr, tidyr, readr, purrr, and more.
"parallel",    # For parallel processing to speed up computations.
"units",       # For handling physical units in data, such as distances and areas. 
"haven",       # For reading and writing data in various formats, including SPSS, Stata, and SAS.
"foreign",     # For reading and writing data in various formats, including SPSS, Stata, and SAS.
"purrr",       # For functional programming
"stringr",     # For string manipulation
"qs2",         # For fast serialization of R objects
"MASS",        # For statistical functions
"Matrix"       # For sparse matrices
)

## ii. Spatial Libraries
pkgs_spatial = c(
"sf",           # For handling spatial vector data using simple features.
"sp",           # For handling spatial data using the older sp package; still used for some
"spdep",        # For spatial dependence and neighborhood definitions.
"stars",        # For handling spatiotemporal arrays, raster and vector data cubes.
"terra",        # Updated package for handling raster data, replacing the older raster package.
"modisfast",    # For fast MODIS data handling
"ggspatial",    # For additional map items (arrows, scale) in gg
"geodata",      # For downloading GADM data
"DEplotting",   # For plotting spatial data with ggplot2
"ncmeta",       # For metadata extraction from NetCDF files
"ncdf4",        # For handling NetCDF files
"waldo",        # For comparing R objects, useful for debugging spatial data manipulations
"geosphere"     # For geospatial calculations, such as distances and bearings
)

## iii. OSRM-related Libraries
pkgs_osrm = c(
"osrm",        # For routing and isochrone calculations using the Open Source Routing Machine 
"osrmr",       # For working with OSRM routing data
"sfnetworks"   # For handling network data in a spatial context, useful for routing
)

## iv. Visualization and Map-creation Libraries
pkgs_viz = c(
"viridis",           # For color scales that are perceptually uniform and colorblind-friendly.
"ggplot2",           # For creating complex and customizable visualizations using the grammar of graphics
"leaflet",           # For creating interactive maps using the Leaflet JavaScript library.
"scales",            # For scaling functions in ggplot2, such as formatting axes and
"ggpubr",            # For publication-ready ggplot2 visualizations
"RColorBrewer",      # For color palettes for maps and visualizations
"plotly",            # For creating interactive web-based visualizations
"leaflet.extras2",   # For additional features in Leaflet maps, such as
"rgl",               # For 3D plotting
"threejs",           # For interactive 3D plotting in web browsers
"grid",              # For advanced plotting and layout control in R
"webshot2",          # For taking screenshots of web-based visualizations
"htmlwidgets",       # For creating interactive web-based visualizations
"tidyterra",         # For ggplot2-like plotting of terra objects
"tmap",               # For thematic mapping, including both static and interactive maps
"mapview"
)

## v. Data download Libraries
pkgs_data_download = c(
"curl",        # For making HTTP requests to download data from the web.
"httr",        # For making HTTP requests to download data from the web, with a
"jsonlite",    # For parsing JSON data, often used in APIs for data retrieval.
"utils",       # For various utility functions, including downloading files.
"RCurl",       # For making HTTP requests to download data from the web, with more
"R.utils",     # For various utility functions, including downloading files and handling compressed data.
"XML",         # For parsing XML data, often used in APIs for data retrieval.
"bonn",        # For downloading and handling data from the Bonn Open Data Portal.
"maptiles",     # For downloading and handling map tiles from various providers, including OpenStreet
"rnaturalearth"
)
# black marbel :: packages for data download 
## vi. Date manipulations
pkgs_date = c(
"zoo"          # For working with regular and irregular time series data, including date manipulations.
)

## vii. Econometrics Libraries
pkgs_econometrics = c(
"fixest",      # For fast estimation of econometric models, including fixed effects and instrumental
"splm",        # For spatial panel data econometrics
"spatialreg",   # For spatial regression models, including spatial lag and spatial error models
"SDPDmod",      # For spatial dynamic panel data models
"plm"           # For panel data econometrics, including fixed effects, random effects, and between effects models
)

## viii . Miscellaneous Libraries
pkgs_misc = c(
"here",          # For constructing file paths relative to the project root, improving reproducibility.
"tictoc",        # For timing and benchmarking code execution.
"keyring",       # For secure storage of API keys and other sensitive information.
"knitr",         # For dynamic report generation, allowing for the integration of R code and
"kableExtra",    # For enhanced table formatting in knitr and R Markdown documents.
"gt",            # For creating tables in R, with a focus on presentation and formatting.
"texreg",        # For creating LaTeX tables from regression output, useful for academic
"pak",           # For package management and installation, providing a faster alternative to install.packages().
"jpeg",          # For handling JPEG images in R, including reading and writing JPEG files.
"webshot",       # For taking screenshots of web-based visualizations, such as those created with Leaflet or Plotly.
"DiagrammeR",    # For creating diagrams and flowcharts in R, using a simple graph specification language.
"DiagrammeRsvg", # For exporting Diagram diagrams as SVG files, allowing for high-quality vector graphics output.
"rsvg",          # For rendering SVG files as images, useful for including DiagrammeR diagrams in reports and presentations. 
"Hmisc",         # For various miscellaneous functions, including data manipulation and analysis tools.
"remotes"        # For installing packages from GitHub and other remote repositories
)


# Install packages if not already installed  ------------------------------------------------

pkgs = c(pkgs_dml, pkgs_spatial, pkgs_osrm, pkgs_viz, pkgs_data_download, pkgs_date, pkgs_econometrics, pkgs_misc)
to_install = !pkgs %in% installed.packages()
if (any(to_install)) {
  install.packages(pkgs[to_install])
}

# Load packages ------------------------------------------------

pkgs = c(pkgs_dml, pkgs_spatial, pkgs_osrm, pkgs_viz, pkgs_data_download, pkgs_date, pkgs_econometrics, pkgs_misc)
lapply(pkgs, library, character.only = TRUE)















