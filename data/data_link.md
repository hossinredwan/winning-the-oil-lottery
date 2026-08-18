# Data link 

## 2 ANP oil-well-data
## 2.1 Master_well_table
meta data =  "https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-acervo-de-dados-tecnicos/metadados-tabela-pocos.pdf"

csv = "https://cdp.anp.gov.br/ords/r/cdp_apex/consulta-dados-publicos-cdp/consulta-de-po%C3%A7os"
- I download it manually , because there is captcha 

## 2.2 Well_shapefiles
meta data = "https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-dados-georreferenciados-das-bacias-sedimentares-brasileiras/metadados-cgu-shapefile-pocos.pdf""

zip file  = ""https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-dados-georreferenciados-das-bacias-sedimentares-brasileiras/shapefile-de-pocos.zip/@@download/file" 

## 2.3 well_result_data

meta data = "https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-resultados-de-poco/metadados-resultado-poco.pdf"

csv = "https://cdp.anp.gov.br/ords/r/cdp_apex/consulta-dados-publicos-cdp/consulta-de-resultado-de-po%C3%A7o?clear=33&session=6111762575008&cs=3uhPBurvOf4G1h0ulZBr08WeynQKeN2EaZ4Eu-rZRl3s-IKhaMcvH_6QJtKoDupzG5aHnXFabYiUDNb6FOmbmog"

- I download it manually , because there is captcha 

## 2.4 Well status and production status 

meta data = "https://view.officeapps.live.com/op/view.aspx?src=https%3A%2F%2Fwww.gov.br%2Fanp%2Fpt-br%2Fcentrais-de-conteudo%2Fdados-abertos%2Farquivos%2Farquivos-fase-de-desenvolvimento-e-producao%2Finformacoes-sobre-pocos%2Fmetadado-situacao-de-poco.docx&wdOrigin=BROWSELINK"

csv = "https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-fase-de-desenvolvimento-e-producao/informacoes-sobre-pocos/situacao-pocos-1939-2026.csv"

# 3 Petroleum GIS layers 

## 3 Sedimentary basins, blocks, and production fields 

- 3.1 shapefile -wells
"https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-dados-georreferenciados-das-bacias-sedimentares-brasileiras/shapefile-de-pocos.zip"
- 3.2 shapefile -  Geophysical Programs 
"https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-dados-georreferenciados-das-bacias-sedimentares-brasileiras/shapefile-naosismico.zip"

- 3.2 shapefile -  Geophysical surveys

"https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-dados-georreferenciados-das-bacias-sedimentares-brasileiras/shapefile-levantamentos-geoquimicos.zip"

- 3.3 Shapefile – Exploratory Blocks Under Contract
"https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-dados-georreferenciados-das-bacias-sedimentares-brasileiras/blocos-exploratorios.zip"

- 3.4 Shapefile – Production Fields
"https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-dados-georreferenciados-das-bacias-sedimentares-brasileiras/campos-producao.zip"

- 3.5 Shapefile – Completed Rounds Blocks
"https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-dados-georreferenciados-das-bacias-sedimentares-brasileiras/shapefiles-rodadas-concluidas.zip"

meta-data : 
"https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-dados-georreferenciados-das-bacias-sedimentares-brasileiras/metadados-shapefile-blocos-exploratorios-sob-contrato.pdf"

"https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-dados-georreferenciados-das-bacias-sedimentares-brasileiras/metadados-shapefile-campos-de-producao.pdf"

"https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-dados-georreferenciados-das-bacias-sedimentares-brasileiras/metadados-cgu-shapefile-rodadas-concluidas.pdf"

"https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-dados-georreferenciados-das-bacias-sedimentares-brasileiras/metadados-cgu-shapefile-pocos.pdf"

"https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-dados-georreferenciados-das-bacias-sedimentares-brasileiras/metadados-cgu-shapefile-programas-geofisicos.pdf"

"https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/arquivos-dados-georreferenciados-das-bacias-sedimentares-brasileiras/metadados-shapefile-levantamentos-geoquimicos.pdf"

# 4 IBGE 

˜˜˜
library(httr)

base <- "https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2000"

ufs <- c(
  "ac","al","am","ap","ba","ce","df","es","go","ma","mg","ms","mt",
  "pa","pb","pe","pi","pr","rj","rn","ro","rr","rs","sc","se","sp","to"
)

dir.create("municipios_2000", showWarnings = FALSE)

for (uf in ufs) {
  url <- sprintf("%s/%s/", base, uf)
  zipfile <- sprintf("municipios_2000/%s.zip", uf)

  # Download directory listing and find the ZIP filename
  listing <- content(GET(url), "text")
  zipname <- regmatches(listing, regexpr("[^\"]+\\.zip", listing))

  if (length(zipname) > 0) {
    download.file(paste0(url, zipname), zipfile, mode = "wb")
    message("Downloaded: ", uf)
  } else {
    message("No ZIP found for: ", uf)
  }
}
˜˜˜
# 5. Municipality-to-MCA crosswalk
# 6.1  Historical municipal GDP
# 6.2  Modern IBGE municipal GDP
# 7    Population census data
 - Censo-demografico_1970 =  "https://ftp.ibge.gov.br/Censos/Censo_Demografico_1970/Microdados/Microdados_Censo_Demografico_1970_Amostra.zip"

 - Censo-demografico_1980 = "https://ftp.ibge.gov.br/Censos/Censo_Demografico_1980/Microdados/Microdados_Censo_Demografico_1980_Amostra.zip""

 - Censo-demografico_1991 = "https://ftp.ibge.gov.br/Censos/Censo_Demografico_1991/"
 - Censo-demografico_2000 = "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/"

 # 8 RAIS 

 http://cemin.wikidot.com/raisr

 