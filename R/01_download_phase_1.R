#===============================================================================
# Phase 1: Oil and GIS data
#
# Downloads/organizes:
#   1. ANP master well table      (manual - captcha)
#   2. ANP well shapefile         (zip)
#   3. ANP well-result data       (manual - captcha)
#   4. ANP well-status data       (csv)
#   5. IBGE municipality 2000 shapefiles (zip, per state)
#   6. Sedimentary basins         (URL missing - TODO)
#   7. Production fields          (zip)
#
# Safe to re-run: existing files/folders are skipped.
#===============================================================================

## ---- 0. Setup ---------------------------------------------------------------

if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
if (!requireNamespace("httr", quietly = TRUE)) install.packages("httr")

library(here)
library(httr)

root      <- here::here()
raw_dir   <- file.path(root, "data", "raw")
temp_dir  <- file.path(raw_dir, "temp")
anp_dir   <- file.path(raw_dir, "anp")
ibge_dir  <- file.path(raw_dir, "ibge_boundaries")

dirs_needed <- c(raw_dir, temp_dir, anp_dir, ibge_dir)
invisible(lapply(dirs_needed, function(d) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}))

## ---- 1. Helper functions -----------------------------------------------------

# Check if a "marker" file/folder already exists (skip condition)
already_downloaded <- function(path) {
  file.exists(path) || dir.exists(path)
}

# Download a .zip to raw/temp/, unzip into dest_dir, then clean up temp file
download_and_unzip <- function(url, dest_dir, zip_name, marker_check = dest_dir) {
  if (already_downloaded(marker_check)) {
    message(sprintf("[SKIP] %s already exists.", marker_check))
    return(invisible(NULL))
  }

  if (!dir.exists(dest_dir)) dir.create(dest_dir, recursive = TRUE)

  temp_zip <- file.path(temp_dir, zip_name)

  message(sprintf("[DOWNLOAD] %s", url))
  download.file(url, destfile = temp_zip, mode = "wb", quiet = FALSE)

  message(sprintf("[UNZIP] -> %s", dest_dir))
  unzip(temp_zip, exdir = dest_dir)

  file.remove(temp_zip)
  message(sprintf("[DONE] %s", dest_dir))
}

# Download a direct (non-zip) file, e.g. .csv
download_direct <- function(url, dest_file) {
  if (already_downloaded(dest_file)) {
    message(sprintf("[SKIP] %s already exists.", dest_file))
    return(invisible(NULL))
  }

  message(sprintf("[DOWNLOAD] %s", url))
  download.file(url, destfile = dest_file, mode = "wb", quiet = FALSE)
  message(sprintf("[DONE] %s", dest_file))
}

# For captcha-protected sources that must be downloaded manually
check_manual_download <- function(expected_file, item_name) {
  if (already_downloaded(expected_file)) {
    message(sprintf("[SKIP] %s already present.", item_name))
  } else {
    warning(sprintf(
      "[MANUAL REQUIRED] %s is not present.\n  -> Download manually (captcha-protected) and place it at:\n     %s",
      item_name, expected_file
    ))
  }
}

## ---- 2. Item-specific download functions -------------------------------------

# 1. ANP master well table (manual only)
download_anp_master_well_table <- function() {
  expected_file <- file.path(anp_dir, "anp_master_well_table.csv")
  check_manual_download(expected_file, "ANP master well table")
}

# 2. ANP well shapefile (zip)
download_anp_well_shapefile <- function() {
  url <- "https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-dados-georreferenciados-das-bacias-sedimentares-brasileiras/shapefile-de-pocos.zip/@@download/file"
  dest <- file.path(anp_dir, "well_shapefile")
  download_and_unzip(url, dest, "anp_well_shapefile.zip")
}

# 3. ANP well-result data (manual only)
download_anp_well_result_data <- function() {
  expected_file <- file.path(anp_dir, "anp_well_result_data.csv")
  check_manual_download(expected_file, "ANP well-result data")
}

# 4. ANP well-status data (csv)
download_anp_well_status_data <- function() {
  url <- "https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-fase-de-desenvolvimento-e-producao/informacoes-sobre-pocos/situacao-pocos-1939-2026.csv"
  dest <- file.path(anp_dir, "situacao-pocos-1939-2026.csv")
  download_direct(url, dest)
}

# 5. IBGE municipality 2000 shapefiles (zip, looped over states)
download_ibge_municipios_2000 <- function() {
  base <- "https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2000"

  ufs <- c(
    "ac", "al", "am", "ap", "ba", "ce", "df", "es", "go", "ma", "mg", "ms", "mt",
    "pa", "pb", "pe", "pi", "pr", "rj", "rn", "ro", "rr", "rs", "sc", "se", "sp", "to"
  )

  for (uf in ufs) {
    uf_dest <- file.path(ibge_dir, uf)

    if (already_downloaded(uf_dest)) {
      message(sprintf("[SKIP] IBGE %s already exists.", uf))
      next
    }

    url <- sprintf("%s/%s/%s_municipios.zip", base, uf, uf)

    tryCatch(
      {
        download_and_unzip(
          url         = url,
          dest_dir    = uf_dest,
          zip_name    = sprintf("ibge_%s.zip", uf),
          marker_check = uf_dest
        )
      },
      error = function(e) {
        warning(sprintf("[FAIL] Could not download IBGE shapefile for %s: %s", uf, conditionMessage(e)))
      }
    )
  }
}

# 6. Sedimentary basins (URL missing - placeholder)
download_sedimentary_basins <- function() {
  dest <- file.path(anp_dir, "sedimentary_basins")

  if (already_downloaded(dest)) {
    message("[SKIP] Sedimentary basins already present.")
    return(invisible(NULL))
  }

  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  message("[INFO] Sedimentary basins source URL is not available in the current metadata. Creating a placeholder folder; add the URL in data/data_link.md to enable the download.")
}

# 7. Production fields (zip)
download_production_fields <- function() {
  url <- "https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-dados-georreferenciados-das-bacias-sedimentares-brasileiras/campos-producao.zip"
  dest <- file.path(anp_dir, "production_fields")
  download_and_unzip(url, dest, "anp_production_fields.zip")
}

## ---- 3. Run all Phase 1 downloads --------------------------------------------

phase1_items <- list(
  list(name = "ANP master well table",          fn = download_anp_master_well_table),
  list(name = "ANP well shapefile",              fn = download_anp_well_shapefile),
  list(name = "ANP well-result data",            fn = download_anp_well_result_data),
  list(name = "ANP well-status data",            fn = download_anp_well_status_data),
  list(name = "IBGE municipality 2000 shapefiles", fn = download_ibge_municipios_2000),
  list(name = "Sedimentary basins",              fn = download_sedimentary_basins),
  list(name = "Production fields",               fn = download_production_fields)
)

message("===== Phase 1: Oil and GIS — starting download run =====")

for (item in phase1_items) {
  message(sprintf("\n--- %s ---", item$name))
  tryCatch(
    item$fn(),
    error = function(e) {
      message(sprintf("[ERROR] %s failed: %s", item$name, conditionMessage(e)))
    }
  )
}

message("\n===== Phase 1 download run complete =====")
