# Initialize project helpers --------------------------------------------------
# This script loads project-wide package and directory helpers.

if (!requireNamespace("here", quietly = TRUE)) {
  install.packages("here")
}

source(here::here("src", "_packages.R"))
source(here::here("src", "_directories.R"))
source(here::here("src", "_functions.R"))
