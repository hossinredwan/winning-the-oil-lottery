# ============================================================
# Search and download historical municipal GDP from Ipeadata
# Project: Winning the Oil Lottery
# ============================================================

# 1. Setup --------------------------------------------------------

options(
  repos = c(CRAN = "https://cloud.r-project.org"),
  timeout = 120
)

required_packages <- c(
  "ipeadatar",
  "dplyr",
  "stringr",
  "purrr",
  "readr",
  "lubridate",
  "tidyr"
)

install_missing_packages <- function(pkgs) {
  missing <- pkgs[!pkgs %in% installed.packages()[, "Package"]]
  if (length(missing) > 0L) {
    install.packages(missing, dependencies = TRUE)
  }
}

install_missing_packages(required_packages)

suppressPackageStartupMessages({
  library(ipeadatar)
  library(dplyr)
  library(stringr)
  library(purrr)
  library(readr)
  library(lubridate)
  library(tidyr)
})

# 2. Create folders -------------------------------------------------------

paths <- c("data/raw/ipeadata", "data/processed")

invisible(
  lapply(paths, function(path) {
    if (!dir.exists(path)) {
      dir.create(path, recursive = TRUE, showWarnings = FALSE)
    }
  })
)

# 3. Search Ipeadata series ----------------------------------------------

search_terms <- c(
  "PIB municipal",
  "Produto Interno Bruto municipal",
  "PIB dos municípios",
  "PIB agropecuária municipal",
  "PIB indústria municipal",
  "PIB serviços municipal"
)

safe_search_series <- purrr::safely(function(term) {
  ipeadatar::search_series(
    terms = term,
    language = "br",
    label = FALSE
  ) %>%
    mutate(search_term = term)
}, otherwise = tibble())

search_results <- search_terms %>%
  set_names() %>%
  map(safe_search_series) %>%
  map_dfr("result") %>%
  distinct(code, .keep_all = TRUE)

if (nrow(search_results) == 0L) {
  stop("No Ipeadata series were returned. Check search terms, network, or API availability.")
}

message("Found ", nrow(search_results), " unique Ipeadata series.")

# 4. Inspect the search results ----------------------------------------

search_results %>%
  select(any_of(c(
    "code",
    "name",
    "theme",
    "source",
    "frequency",
    "status",
    "search_term"
  ))) %>%
  print(n = Inf)

# 5. Save all candidate series -----------------------------------------

write_csv(
  search_results,
  "data/raw/ipeadata/ipeadata_gdp_search_results.csv",
  na = ""
)

# 6. Select likely historical municipal GDP series -----------------------

gdp_candidates <- search_results |>
  filter(
    str_detect(
      str_to_lower(name),
      "pib|produto interno bruto"
    )
  ) |>
  filter(
    str_detect(
      str_to_lower(name),
      "municip"
    )
  ) |>
  arrange(name)

print(
  gdp_candidates |>
    select(any_of(c(
      "code",
      "name",
      "theme",
      "source",
      "frequency",
      "last_update",
      "status"
    ))),
  n = Inf
)

write_csv(
  gdp_candidates,
  "data/raw/ipeadata/municipal_gdp_candidates.csv"
)

# 7. Download metadata for candidate series ------------------------------

candidate_codes <- unique(gdp_candidates$code)

if (length(candidate_codes) == 0) {
  stop(
    paste(
      "No municipal GDP series were found.",
      "Open data/raw/ipeadata/ipeadata_gdp_search_results.csv",
      "and inspect the broader search results."
    )
  )
}

gdp_metadata <- ipeadatar::metadata(
  code = candidate_codes,
  language = "br",
  label = FALSE,
  quiet = FALSE
)

print(gdp_metadata, n = Inf)

write_csv(
  gdp_metadata,
  "data/raw/ipeadata/municipal_gdp_metadata.csv"
)

gdp_metadata |>
  select(any_of(c(
    "code",
    "name",
    "comments",
    "source",
    "frequency",
    "unit",
    "multiplier",
    "status"
  ))) |>
  print(n = Inf)

# 8. Download data for all candidate GDP series --------------------------

gdp_raw <- ipeadatar::ipeadata(
  code = candidate_codes,
  language = "br",
  label = FALSE,
  quiet = FALSE
)

glimpse(gdp_raw)

write_csv(
  gdp_raw,
  "data/raw/ipeadata/municipal_gdp_all_candidates.csv"
)

saveRDS(
  gdp_raw,
  "data/raw/ipeadata/municipal_gdp_all_candidates.rds"
)

# 9. Examine year coverage ------------------------------------------------

gdp_year_coverage <- gdp_raw |>
  mutate(year = lubridate::year(date)) |>
  group_by(code) |>
  summarise(
    first_year = min(year, na.rm = TRUE),
    last_year  = max(year, na.rm = TRUE),
    years_available = paste(
      sort(unique(year)),
      collapse = ", "
    ),
    observations = n(),
    .groups = "drop"
  ) |>
  left_join(
    gdp_metadata |>
      select(any_of(c("code", "name", "unit", "source"))),
    by = "code"
  ) |>
  select(
    code,
    name,
    first_year,
    last_year,
    years_available,
    observations,
    everything()
  )

print(gdp_year_coverage, n = Inf)

write_csv(
  gdp_year_coverage,
  "data/raw/ipeadata/municipal_gdp_year_coverage.csv"
)

# 10. Keep years relevant to the replication ------------------------------

target_years <- c(
  1949,
  1959,
  1970,
  1975,
  1980,
  1985,
  1996,
  2000
)

gdp_replication_period <- gdp_raw

if (!"territorial_code" %in% names(gdp_replication_period)) {
  gdp_replication_period <- gdp_replication_period |>
    mutate(territorial_code = tcode)
} else {
  gdp_replication_period <- gdp_replication_period |>
    mutate(territorial_code = coalesce(territorial_code, tcode))
}

gdp_replication_period <- gdp_replication_period |>
  mutate(year = lubridate::year(date)) |>
  filter(year %in% target_years) |>
  arrange(code, territorial_code, year)

write_csv(
  gdp_replication_period,
  "data/processed/municipal_gdp_1949_2000_long.csv"
)

saveRDS(
  gdp_replication_period,
  "data/processed/municipal_gdp_1949_2000_long.rds"
)