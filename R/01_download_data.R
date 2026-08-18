# Download ANP georeferenced well data shapefile
# Downloads the ZIP archive to data/temp/ and extracts it to data/raw/anp/

library(utils)
library(here)

# --- Configuration ---
url <- "https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-dados-georreferenciados-das-bacias-sedimentares-brasileiras/shapefile-de-pocos.zip/@@download/file"
zip_path <- here::here("data", "temp", "shapefile-de-pocos.zip")
extract_dir <- here::here("data", "raw", "anp", "well_shapefiles")

# --- Create directories ---
dir.create(dirname(zip_path), recursive = TRUE, showWarnings = FALSE)
dir.create(extract_dir, recursive = TRUE, showWarnings = FALSE)

# --- Download file ---
message("Downloading ANP shapefile archive...")
download.file(url, destfile = zip_path, mode = "wb", quiet = FALSE)

# --- Extract archive ---
message("Extracting archive to ", extract_dir)
unzip(zip_path, exdir = extract_dir)

message("Download and extraction completed.")

library(httr2)
library(fs)

download_anp_wells <- function(
    destination = "data/raw/anp/situacao_pocos_1939_2026.csv",
    overwrite = FALSE) {

  url <- paste0(
    "https://www.gov.br/anp/pt-br/centrais-de-conteudo/",
    "dados-abertos/arquivos/arquivos-fase-de-desenvolvimento-e-producao/",
    "informacoes-sobre-pocos/situacao-pocos-1939-2026.csv"
  )

  dir_create(path_dir(destination))

  if (file_exists(destination) && !overwrite) {
    message("File already exists: ", destination)
    return(invisible(destination))
  }

  response <- request(url) |>
    req_user_agent(
      "Winning the Oil Lottery replication; academic use"
    ) |>
    req_retry(
      max_tries = 5,
      backoff = function(tries) tries * 2
    ) |>
    req_perform(path = destination)

  message("ANP well data downloaded successfully.")
  invisible(destination)
}

download_anp_wells()