# Data Download Checklist
## Replication of *Winning the Oil Lottery*

**Paper:** Cavalcanti, T., Da Mata, D., & Toscani, F. (2019)  
**Study period:** 1940–2000  
**Main unit:** 1,275 Minimum Comparable Areas (MCAs)  
**Treatment:** Drilling followed by oil discovery  
**Control:** Drilling without discovery  

---

## 1. Project folders

```text
data/
├── raw/
│   ├── anp/
│   │   ├── well_table/
│   │   ├── well_results/
│   │   ├── well_shapefile/
│   │   ├── producing_wells/
│   │   ├── sedimentary_basins/
│   │   └── production_fields/
│   ├── ibge_boundaries/
│   ├── crosswalks/
│   ├── municipal_gdp/
│   ├── ibge_census/
│   ├── rais/
│   ├── ipeadata/
│   └── institutional_data/
├── intermediate/
└── processed/
```

---

## 2. ANP oil-well data

### 2.1 Master well table — Essential

**Purpose**

- Identify drilled wells
- Obtain drilling dates
- Obtain well coordinates
- Identify discovery, dry-hole, and producer status
- Assign wells to municipalities and MCAs

**Required variables**

- [ ] Well identifier
- [ ] Well name
- [ ] Latitude and longitude
- [ ] State and sedimentary basin
- [ ] Onshore/offshore indicator
- [ ] Drilling start and completion dates
- [ ] Well result
- [ ] Discovery category
- [ ] Dry-hole category
- [ ] Producer status
- [ ] Field name
- [ ] Operator

**Source**

ANP Technical Data Archive:  
https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/acervo-de-dados-tecnicos

**Download tasks**

- [ ] Locate `Tabela de Poços`
- [ ] Download the data file
- [ ] Download metadata
- [ ] Check coverage before 2001
- [ ] Record download date and original filename
- [ ] Check encoding and coordinate fields

**Save to**

```text
data/raw/anp/well_table/
```

---

### 2.2 Well shapefile — Essential

**Purpose**

- Map wells
- Spatially join onshore wells to municipalities
- Assign offshore wells to nearest coastal municipality
- Support spillover analysis

**Source**

ANP georeferenced data:  
https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/dados-georreferenciados-das-bacias-sedimentares-brasileiras

**Download tasks**

- [ ] Download `shapefile-de-pocos.zip`
- [ ] Download metadata
- [ ] Extract `.shp`, `.dbf`, `.shx`, `.prj`, and `.cpg`
- [ ] Check CRS
- [ ] Compare well IDs with the master table
- [ ] Filter to 1940–2000
- [ ] Check for duplicate wells

**Save to**

```text
data/raw/anp/well_shapefile/
```

---

### 2.3 Well-result data — Essential

**Purpose**

Classify wells as:

- New-field discovery
- Reservoir or subfield discovery
- Field-extension discovery
- Dry hole
- Abandoned
- Non-commercial discovery
- Producer well

**Source**

ANP well results:  
https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/resultados-de-poco

**Download tasks**

- [ ] Download/export all available records
- [ ] Download metadata
- [ ] Identify the well ID
- [ ] Match results to the master table
- [ ] List all original categories
- [ ] Translate Portuguese labels
- [ ] Build a classification dictionary
- [ ] Preserve missing and unknown values

**Suggested dictionary**

```text
original_result
standardized_result
discovery_indicator
true_discovery_indicator
dry_hole_indicator
producer_indicator
notes
```

**Save to**

```text
data/raw/anp/well_results/
```

---

### 2.4 Well status and production status — Important

**Purpose**

- Identify producer wells
- Construct first production year
- Measure discovery-to-production delay

**Source**

ANP development and production data:  
https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/fase-de-desenvolvimento-e-producao

**Download tasks**

- [ ] Download `Situação de Poços`
- [ ] Download metadata
- [ ] Match well IDs
- [ ] Identify historical producer status
- [ ] Do not rely only on current status
- [ ] Construct first production year

**Save to**

```text
data/raw/anp/producing_wells/
```

---

### 2.5 Monthly production by well — Extension

**Purpose**

Use only for a post-2005 production-intensity extension.

**Source**

https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/producao-de-petroleo-e-gas-natural-por-poco

**Tasks**

- [ ] Download onshore production
- [ ] Download offshore production
- [ ] Aggregate monthly data to annual well production
- [ ] Aggregate wells to municipality or MCA

---

## 3. Petroleum GIS layers

### Sedimentary basins, blocks, and production fields

**Purpose**

- Geological context
- Maps
- Balance checks
- Spillover analysis

**Source**

https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/dados-georreferenciados-das-bacias-sedimentares-brasileiras

**Tasks**

- [ ] Download sedimentary basin polygons
- [ ] Download exploratory blocks
- [ ] Download production fields
- [ ] Download metadata
- [ ] Reproject all layers to a common CRS

**Save to**

```text
data/raw/anp/sedimentary_basins/
data/raw/anp/exploratory_blocks/
data/raw/anp/production_fields/
```

---

## 4. IBGE municipality boundaries

### Municipality boundaries for 2000 — Essential

**Purpose**

- Assign wells to municipalities
- Calculate areas and centroids
- Identify coastal municipalities
- Create spatial-neighbor matrices
- Aggregate municipalities to MCAs

**Source**

IBGE municipality 2000 meshes:  
https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2000/

**Tasks**

- [ ] Download municipality ZIP files for all 27 federal units
- [ ] Extract all shapefiles
- [ ] Read with `sf::st_read()`
- [ ] Combine with `dplyr::bind_rows()`
- [ ] Preserve IBGE municipality codes
- [ ] Repair geometry with `sf::st_make_valid()`
- [ ] Confirm approximately 5,507 municipalities
- [ ] Calculate area
- [ ] Create points on surface
- [ ] Identify coastal municipalities

**Save to**

```text
data/raw/ibge_boundaries/municipalities_2000/
```

---

## 5. Minimum Comparable Areas crosswalk

### Municipality-to-MCA crosswalk — Essential for exact replication

**Required structure**

```text
municipality_code
municipality_name
state_code
census_year
mca_id
mca_name
```

**Possible sources**

1. Paper supplementary material
2. IPEA/Ipeadata
3. Reis et al. historical data
4. Da Mata et al. correspondence files
5. Direct request to the authors

**Search terms**

```text
Área Mínima Comparável
Áreas Mínimas Comparáveis
AMC 1940-2000
Minimum Comparable Areas Brazil
municipality MCA crosswalk
```

**Tasks**

- [ ] Search supplementary files
- [ ] Search IPEA/Ipeadata
- [ ] Search authors’ pages and repositories
- [ ] Contact authors if unavailable
- [ ] Verify 1,275 MCAs
- [ ] Verify every 2000 municipality has an MCA ID
- [ ] Document manual corrections

**Save to**

```text
data/raw/crosswalks/municipality_to_mca/
```

**Fallback**

Use 2000 municipalities and describe the study as an approximate public-data reconstruction.

---

## 6. Historical municipal GDP

### Historical GDP panel — Essential for main results

**Study years**

- [ ] 1949
- [ ] 1959
- [ ] 1970
- [ ] 1975
- [ ] 1980
- [ ] 1985
- [ ] 1996
- [ ] 2000

**Required variables**

```text
mca_id
year
total_gdp
agriculture_value_added
manufacturing_value_added
services_value_added
population
gdp_per_capita
price_deflator
```

**Possible sources**

- Authors’ replication data
- IPEA/Ipeadata
- Historical Economic Censuses
- Reis et al. municipal GDP files

**Search terms**

```text
PIB municipal histórico Brasil
PIB municipal 1949 1959
Reis PIB municipal
municipal value added Brazil historical
```

**Tasks**

- [ ] Request authors’ harmonized GDP file
- [ ] Request codebook and deflator
- [ ] Search IPEA repositories
- [ ] Keep modern substitutes separate
- [ ] Document whether figures are nominal or real
- [ ] Document sector definitions

**Save to**

```text
data/raw/municipal_gdp/historical/
```

---

### Modern IBGE municipal GDP — Fallback/extension

**Source**

https://www.ibge.gov.br/estatisticas/economicas/contas-nacionais/9088-produto-interno-bruto-dos-municipios.html

**Tasks**

- [ ] Download total GDP
- [ ] Download GDP per capita
- [ ] Download agriculture value added
- [ ] Download industry value added
- [ ] Download services value added
- [ ] Preserve IBGE municipality codes

---

## 7. Population census data

### Historical census years

- [ ] 1940
- [ ] 1950
- [ ] 1960
- [ ] 1970
- [ ] 1980
- [ ] 1991
- [ ] 1996 population count
- [ ] 2000

**Main variables**

- [ ] Total population
- [ ] Urban and rural population
- [ ] Population density
- [ ] Literacy and education
- [ ] Employment
- [ ] Agriculture and fishing
- [ ] Manufacturing and extraction
- [ ] Retail
- [ ] Transportation
- [ ] Public sector
- [ ] Services
- [ ] Formal and informal employment

**Sources**

IBGE Census archive:  
https://ftp.ibge.gov.br/Censos/

IBGE SIDRA:  
https://sidra.ibge.gov.br/

**Tasks for each year**

- [ ] Download documentation first
- [ ] Download municipal aggregate tables
- [ ] Download municipality-code lists
- [ ] Download occupation/industry classifications
- [ ] Record weights and missing-value codes
- [ ] Harmonize sectors
- [ ] Match municipalities to MCAs

**Save to**

```text
data/raw/ibge_census/YYYY/
```

---

### Census 2000 aggregates

**Source**

https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/

**Tasks**

- [ ] Download methodology
- [ ] Download `Dados do Universo`
- [ ] Download population tables
- [ ] Download employment and income tables
- [ ] Download education tables
- [ ] Download geographic-code documentation

---

### Census 2000 microdata

**Source**

https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/Microdados/

**Required variables**

- [ ] Municipality/geographic identifier
- [ ] Person weight
- [ ] Employment status
- [ ] Formality status
- [ ] Industry
- [ ] Occupation
- [ ] Earnings
- [ ] Education
- [ ] Age and sex
- [ ] Urban/rural status

**Tasks**

- [ ] Download documentation first
- [ ] Download state files
- [ ] Start with BA, RJ, SE, RN, ES, AL, and AM
- [ ] Identify person weights
- [ ] Check municipality identification
- [ ] Import state files separately
- [ ] Aggregate to municipality/MCA

---

## 8. RAIS 2000

### Worker microdata

**Purpose**

- Formal employment
- Wages
- Worker density
- Employment by skill and sector

**Source**

https://www.gov.br/trabalho-e-emprego/pt-br/assuntos/estatisticas-trabalho/microdados-rais-e-caged

**Tasks**

- [ ] Download RAIS Trabalhador 2000
- [ ] Download layout and dictionary
- [ ] Confirm delimiter and encoding
- [ ] Check municipality codes
- [ ] Import with `data.table`, `arrow`, or `duckdb`
- [ ] Do not open the full file in Excel
- [ ] Aggregate before saving processed data

**Save to**

```text
data/raw/rais/worker_2000/
```

### Establishment microdata

**Purpose**

- Number of firms
- Firm density
- Firms by sector
- Establishment size

**Tasks**

- [ ] Download RAIS Estabelecimento 2000
- [ ] Download layout and dictionary
- [ ] Check duplicate establishments
- [ ] Aggregate firms by municipality and sector
- [ ] Match municipalities to MCAs

**Save to**

```text
data/raw/rais/establishment_2000/
```

---

## 9. Geographic and climatic controls

### Ipeadata variables

- [ ] Average temperature
- [ ] Average rainfall
- [ ] Average altitude

**Source**

http://www.ipeadata.gov.br/

**Tasks**

- [ ] Record units and reference periods
- [ ] Download metadata
- [ ] Preserve municipality codes
- [ ] Aggregate to MCAs

### Constructed GIS controls

- [ ] Latitude and longitude
- [ ] Distance to state capital
- [ ] Coastal indicator
- [ ] Legal Amazon indicator
- [ ] Semiarid-region indicator

Use projected coordinates for distance calculations.

---

## 10. Treatment and control variables

### Drilling

```text
drilling_mca = 1
```

when at least one well was drilled.

- [ ] Find first drilling year
- [ ] Construct cumulative drilling status

### All discovery

At least one:

- [ ] New-field discovery
- [ ] Reservoir/subfield discovery
- [ ] Field-extension discovery

### True discovery

- [ ] Confirm exact definition from the appendix
- [ ] Construct stricter indicator
- [ ] Compare sample size with the paper

### Production

```text
production_mca = 1
```

when at least one producer well operates in the MCA.

- [ ] Find first production year
- [ ] Construct cumulative production status

### Control group

```text
drilling = 1
discovery = 0
```

- [ ] Exclude areas with no drilling
- [ ] Keep unsuccessful exploration areas
- [ ] Check later discoveries

---

## 11. Spatial spillover extension

**Required data**

- [ ] Municipality/MCA polygons
- [ ] Treatment status
- [ ] Outcome panel
- [ ] Border-neighbor matrix
- [ ] Distance-band matrix
- [ ] Well coordinates
- [ ] Production fields

**Variables to construct**

- [ ] Neighbor of treated area
- [ ] Number of treated neighbors
- [ ] Distance to nearest discovery
- [ ] Distance to nearest producer well
- [ ] Discovery within 25 km
- [ ] Discovery within 50 km
- [ ] Discovery within 100 km

---

## 12. Availability summary

| Dataset | Source | Availability | Exact replication |
|---|---|---|---|
| Well inventory | ANP | Public | Approximate |
| Well coordinates | ANP shapefile | Public | Approximate |
| Well results | ANP | Public/query system | Uncertain |
| Producer status | ANP | Public | Approximate |
| Municipality boundaries | IBGE | Public | Partial |
| MCA crosswalk | IPEA/authors | Uncertain | Author-dependent |
| Historical GDP | IPEA/authors | Uncertain | Author-dependent |
| Census aggregates | IBGE | Mostly public | Requires harmonization |
| Census 2000 microdata | IBGE | Public | Mostly feasible |
| RAIS worker data | Ministry of Labor | Public | Feasible |
| RAIS establishment data | Ministry of Labor | Public | Feasible |
| Climate/altitude | Ipeadata | Likely public | Feasible |
| Spatial controls | Constructed | Public inputs | Feasible |

---

## 13. Recommended download order

### Phase 1 — Oil and GIS

- [ ] ANP master well table
- [ ] ANP well shapefile
- [ ] ANP well-result data
- [ ] ANP well-status data
- [ ] IBGE municipality 2000 shapefiles
- [ ] Sedimentary basins
- [ ] Production fields

### Phase 2 — Analytical geography

- [ ] Municipality-to-MCA crosswalk
- [ ] Aggregate municipality polygons to MCAs
- [ ] Assign wells to MCAs
- [ ] Assign offshore wells to nearest coastal MCA

### Phase 3 — Treatment and control

- [ ] First drilling year
- [ ] First discovery year
- [ ] All-discovery indicator
- [ ] True-discovery indicator
- [ ] First production year
- [ ] Drilled-without-discovery controls

### Phase 4 — Outcomes

- [ ] Historical GDP
- [ ] Sectoral GDP
- [ ] Population
- [ ] Urbanization
- [ ] Employment
- [ ] Education

### Phase 5 — Mechanisms

- [ ] Census 2000 aggregates
- [ ] Census 2000 microdata
- [ ] RAIS worker data
- [ ] RAIS establishment data

### Phase 6 — Controls and spillovers

- [ ] Climate and altitude
- [ ] State-capital distance
- [ ] Coastal/Amazon/semiarid indicators
- [ ] Neighbor and distance-band variables

---

## 14. First download session

Start with only:

- [ ] ANP well table and metadata
- [ ] ANP well shapefile and metadata
- [ ] ANP well results and metadata
- [ ] ANP well status
- [ ] IBGE municipality 2000 shapefiles
- [ ] Sedimentary basins
- [ ] Production fields
- [ ] Paper supplementary material
- [ ] Available MCA crosswalk

**First technical target**

> Map all wells drilled through 2000 and classify municipalities as discovery, unsuccessful drilling, and production locations.

---

## 15. Download inventory

Create:

```text
docs/data_inventory.csv
```

Recommended columns:

```csv
dataset_id,dataset_name,agency,source_page,direct_url,download_date,raw_path,format,coverage,geographic_unit,status,exact_or_substitute,notes
```

For every file, record:

- [ ] Dataset name
- [ ] Agency
- [ ] Source page
- [ ] Direct download URL
- [ ] Original filename
- [ ] Download date
- [ ] File size
- [ ] Format
- [ ] Coverage years
- [ ] Geographic unit
- [ ] CRS
- [ ] Encoding
- [ ] Version/update date
- [ ] Notes

---

## 16. Replication label

Until the exact MCA crosswalk and harmonized historical GDP/census files are obtained, describe the project as:

> A public-data reconstruction and spatial extension of Cavalcanti, Da Mata, and Toscani (2019).

Do not call it an exact replication unless the original harmonized inputs can be reproduced.
