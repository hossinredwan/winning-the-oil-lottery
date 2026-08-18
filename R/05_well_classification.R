# ============================================================
# 05_well_classification.R
# Standardize ANP well-result categories for Table 1
# ============================================================

library(dplyr)
library(tidyr)
library(sf)
library(here)

# ------------------------------------------------------------
# 1. Load final well-to-MCA dataset
# ------------------------------------------------------------

wells <- readRDS(
  here::here(
    "data",
    "processed",
    "wells_mca_1940_2000.rds"
  )
)

message("Loaded wells: ", nrow(wells))


# ------------------------------------------------------------
# 2. Create standardized Table 1 classification
# ------------------------------------------------------------

wells_table1 <- wells %>%
  st_drop_geometry() %>%
  mutate(

    location = case_when(
      TERRA_MAR == "M" ~ "Offshore",
      TERRA_MAR == "T" ~ "Onshore",
      TRUE ~ NA_character_
    ),

    table1_category = case_when(

      # ------------------------------
      # Exploratory wells
      # ------------------------------

      grepl(
        "^DESCOBRIDOR DE CAMPO",
        RECLASSIFI,
        ignore.case = TRUE
      ) ~ "Discovery of new field",

      grepl(
        "^DESCOBRIDOR DE NOVA JAZIDA",
        RECLASSIFI,
        ignore.case = TRUE
      ) ~ "Discovery of new subfield (reservoir)",

      grepl(
        "^EXTENSÃO PARA",
        RECLASSIFI,
        ignore.case = TRUE
      ) ~ "Discovery of field extension (step-out)",

      grepl(
        "^SECO",
        RECLASSIFI,
        ignore.case = TRUE
      ) &
        CATEGORIA != "Desenvolvimento" ~ "Dry Hole - Exploratory",


      # ------------------------------
      # Development wells
      # ------------------------------

      grepl(
        "^PRODUTOR COMERCIAL",
        RECLASSIFI,
        ignore.case = TRUE
      ) ~ "Producer",

      grepl(
        "^PORTADOR",
        RECLASSIFI,
        ignore.case = TRUE
      ) ~ "Carries oil or gas",

      grepl(
        "^PRODUTOR SUBCOMERCIAL",
        RECLASSIFI,
        ignore.case = TRUE
      ) ~ "Production not feasible",

      grepl(
        "^INJEÇÃO",
        RECLASSIFI,
        ignore.case = TRUE
      ) ~ "Injection of water, steam, or gas",

      grepl(
        "^SECO",
        RECLASSIFI,
        ignore.case = TRUE
      ) &
        CATEGORIA == "Desenvolvimento" ~ "Dry Hole - Development",


      # ------------------------------
      # Other
      # ------------------------------

      grepl(
        "^ABANDONADO",
        RECLASSIFI,
        ignore.case = TRUE
      ) ~ "Abandoned",

      CATEGORIA == "Especial" ~ "Special",

      is.na(RECLASSIFI) |
        RECLASSIFI == "" ~ "Missing category",

      TRUE ~ "Other / review"
    )
  )


# ------------------------------------------------------------
# 3. Count offshore and onshore
# ------------------------------------------------------------

table1_counts <- wells_table1 %>%
  count(
    table1_category,
    location,
    name = "n"
  ) %>%
  pivot_wider(
    names_from = location,
    values_from = n,
    values_fill = 0
  ) %>%
  mutate(
    Total = Offshore + Onshore
  )


# ------------------------------------------------------------
# 4. Order rows like the paper
# ------------------------------------------------------------

table1_order <- c(
  "Discovery of new field",
  "Discovery of new subfield (reservoir)",
  "Discovery of field extension (step-out)",
  "Dry Hole - Exploratory",
  "Producer",
  "Carries oil or gas",
  "Production not feasible",
  "Injection of water, steam, or gas",
  "Dry Hole - Development",
  "Abandoned",
  "Special",
  "Missing category",
  "Other / review"
)

table1_final <- table1_counts %>%
  mutate(
    table1_category = factor(
      table1_category,
      levels = table1_order
    )
  ) %>%
  arrange(table1_category)

table1_grouped <- table1_final %>%
  mutate(
    Classification = case_when(
      table1_category %in% c(
        "Discovery of new field",
        "Discovery of new subfield (reservoir)",
        "Discovery of field extension (step-out)",
        "Dry Hole - Exploratory"
      ) ~ "Exploratory wells",

      table1_category %in% c(
        "Producer",
        "Carries oil or gas",
        "Production not feasible",
        "Injection of water, steam, or gas",
        "Dry Hole - Development"
      ) ~ "Development wells",

      TRUE ~ "Other"
    ),

    `Category of well` = case_when(
      table1_category == "Dry Hole - Exploratory" ~ "Dry Hole",
      table1_category == "Dry Hole - Development" ~ "Dry Hole",
      table1_category == "Missing / undefined category" ~ "Missing / undefined category",
      TRUE ~ as.character(table1_category)
    )
  ) %>%
  select(
    Classification,
    `Category of well`,
    Offshore,
    Onshore,
    Total
  )


# ------------------------------------------------------------
# 5. Inspect result
# ------------------------------------------------------------

print(
  as.data.frame(table1_grouped),
  row.names = FALSE
)


# ------------------------------------------------------------
# 6. Check total
# ------------------------------------------------------------

message(
  "Total wells represented in table: ",
  sum(table1_final$Total)
)

message(
  "Expected assigned wells: ",
  nrow(wells)
)


# ------------------------------------------------------------
# 7. Save classification
# ------------------------------------------------------------

saveRDS(
  wells_table1,
  here::here(
    "data",
    "processed",
    "wells_classified_1940_2000.rds"
  )
)

write.csv(
  table1_grouped,
  here::here(
    "outputs",
    "tables",
    "table1_well_categories.csv"
  ),
  row.names = FALSE
)

# inspect unresolved 187

other_review <- wells_table1 %>%
  filter(table1_category == "Other / review") %>%
  count(
    CATEGORIA,
    RECLASSIFI,
    sort = TRUE
  )

print(
  as.data.frame(other_review),
  row.names = FALSE
)

# Inspect 43 "Carries_oil_or_gas

carries_check <- wells_table1 %>%
  filter(table1_category == "Carries oil or gas") %>%
  count(
    CATEGORIA,
    RECLASSIFI,
    sort = TRUE
  )

print(
  as.data.frame(carries_check),
  row.names = FALSE
)

# install.packages("gt")   # run once if needed
library(gt)

total_row <- tibble(
  Classification = "",
  `Category of well` = "**Total**",
  Offshore = sum(table1_grouped$Offshore),
  Onshore = sum(table1_grouped$Onshore),
  Total = sum(table1_grouped$Total)
)

table1_grouped <- bind_rows(
  table1_grouped,
  total_row
)

table1_gt <- table1_grouped %>%
  gt(
    groupname_col = "Classification"
  ) %>%
  cols_label(
    `Category of well` = "Category of well",
    Offshore = "Offshore",
    Onshore = "Onshore",
    Total = "Total"
  ) %>%
  tab_header(
    title = md("**Table 1**  Number of wells by category")
  ) %>%
  fmt_integer(
    columns = c(Offshore, Onshore, Total),
    use_seps = TRUE
  ) %>%
  cols_align(
    align = "left",
    columns = `Category of well`
  ) %>%
  cols_align(
    align = "right",
    columns = c(Offshore, Onshore, Total)
  ) %>%
  tab_source_note(
    source_note = md(
      "Source: calculations using ANP well records, 1940–2000."
    )
  )

table1_gt

dir.create(
  here::here("outputs", "tables"),
  recursive = TRUE,
  showWarnings = FALSE
)

gtsave(
  table1_gt,
  here::here(
    "outputs",
    "tables",
    "table1_well_classification.html"
  )
)