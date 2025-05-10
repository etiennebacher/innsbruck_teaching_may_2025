#####################################################################
## Webscrape election results for municipal elections for all municipalities
#####################################################################

### Ex: https://resultados.elpais.com/elecciones/2019/municipales/01/04/19.html

library(tidyverse)
library(rvest)
library(xml2)


### Workflow on the website:
### - select a year
### - select a comunidad
### - select a provincia (choices depend on the comunidad)
### - select a municipality (choices depend on the provincia)
###

### Code plan:
###
### - get all comunidad ids
### - for each comunidad, get all provincia ids
### - for each provincia, get all municipalities ids
###
### For each comunidad-provincia-municipality combination, get the XML data
### and treat it.
###
### Repeat for each year (2007, 2011, 2015, 2019)



##########
## Get all ids for the comunidad select input ##
##########

com_id <- lapply(1:19, function(x) {
  ids <- as.character(x)
  if (nchar(ids) == 1)
    paste0("0", ids)
  else
    ids
}) %>% unlist()



##########
## Get names for comunidad and province ##
##########

### Get name and index for comunidad

address <- "https://resultados.elpais.com/elecciones/2019/municipales/"

com_info <- read_html(paste0(address, "01")) %>%
  html_nodes(xpath = "/html/body/div[2]/main/div[4]/div[1]/div[2]/div[1]/div[1]/select") %>%
  html_children()

com_name <- data.frame(
  com_index = com_info %>%
    html_attr("id"),
  comunidad = com_info %>%
    html_text()
) %>%
  filter(comunidad != "Comunidad") %>%
  mutate(com_index = ifelse(nchar(com_index) == 1,
                            paste0("0", com_index),
                            com_index))


### Get name and index for province

prov_name <- list()
for (i in com_id) {

  # Get names
  names_prov <- read_html(paste0(address, i)) %>%
    html_nodes(xpath = "/html/body/div[2]/main/div[4]/div[1]/div[2]/div[1]/div[2]/select") %>%
    html_children() %>%
    html_text()

  # Get id
  prov_id <- read_html(paste0(address, i)) %>%
    html_nodes(xpath = "/html/body/div[2]/main/div[4]/div[1]/div[2]/div[1]/div[2]/select") %>%
    html_children() %>%
    html_attr("id")
  prov_id <- prov_id[!is.na(prov_id)]

  # Remove placeholder
  names_prov2 <- names_prov[names_prov != "Provincia"]
  if (length(names_prov2) == 0)
    names_prov2 <- "Single provincia"
  else
    names_prov2

  if (length(names_prov2) == 1 && names_prov2 == "Single provincia")
    prov_id <- NA

  prov_name[[paste0("id", i)]] <- data.frame(
    comunidad = i,
    prov_index = prov_id,
    provincia = names_prov2
  )

}

prov_name <- data.table::rbindlist(prov_name)


### Merge index and names for comunidad and provincia

com_prov_name <- left_join(
  com_name,
  prov_name,
  by = c("com_index" = "comunidad")
) %>%
  mutate(provincia = ifelse(comunidad %in% c("Melilla", "Ceuta"),
                            "Not provincia",
                            provincia),
         prov_index = ifelse(nchar(prov_index) == 1,
                             paste0("0", prov_index),
                             prov_index))

# Note : 50 comunidad (7 of which are made of a single province), 2 are not comunidad (Melilla and Ceuta)




##########
## Function to get and treat XML data for each municipality ##
##########

### Inputs: year, comunidad id, provincia id, municipio id
### Output: table with ids, party, year, results

get_data_xml <- function(year, com, prov, muni) {

  # Get XML data
  test <- read_xml(paste0("https://rsl00.epimg.net/elecciones/", year, "/municipales/", com, "/", prov, "/", muni, ".xml2")) %>%
    as_list() %>%
    purrr::pluck(1)

  # Extract info for results, municipality and year
  resultados <- test %>%
    pluck("resultados")
  resultados <- resultados[-1]

  municipality <- test %>%
    pluck("nombre_sitio") %>%
    unlist()

  year <- test %>%
    pluck("convocatoria") %>%
    unlist()

  # Create dataframe
  lapply(resultados, function(x) {
    foo <- unlist(x) %>%
      as_tibble()
    foo <- foo[-1, ]
    foo <- foo %>%
      mutate(var = c("party_name", "elected_members",
                     "votes", "share_votes")) %>%
      pivot_wider(
        id_cols = "var",
        names_from = "var",
        values_from = "value"
      )
  }) %>%
    enframe() %>%
    unnest("value") %>%
    select(-name) %>%
    mutate(
      com_index = com,
      prov_index = prov,
      munic = municipality,
      year = year
    ) %>%
    select(com_index, prov_index, munic, year, everything())

}



##########
## Loop through all year-comunidad-provincia-municipality combination ##
##########

list_results <- list()

### Year
for (y in c("2007", "2011", "2015", "2019")) {

  address <- paste0("https://resultados.elpais.com/elecciones/", y, "/municipales/")

  ### Comunidad
  for (i in com_id) {

    prov_id <- read_html(paste0(address, i)) %>%
      html_nodes(xpath = "/html/body/div[2]/main/div[4]/div[1]/div[2]/div[1]/div[2]/select") %>%
      html_children() %>%
      html_attr("id")
    prov_id <- prov_id[!is.na(prov_id)]

    com_name <- unique(
      com_prov_name[com_prov_name$com_index == i, "comunidad"]
    )

    # Some comunidad have no (or only one provincia), hence the second
    # selectinput is empty, so I need to provide the provincia index
    # manually.
    if (com_name == "Asturias") {
      prov_id <- "33"
    } else if (com_name == "Baleares") {
      prov_id <- "07"
    } else if (com_name == "Cantabria") {
      prov_id <- "39"
    } else if (com_name == "Madrid") {
      prov_id <- "28"
    } else if (com_name == "Murcia") {
      prov_id <- "30"
    } else if (com_name == "Navarra") {
      prov_id <- "31"
    } else if (com_name == "La Rioja") {
      prov_id <- "26"
    } else if (com_name == "Ceuta") {
      prov_id <- "51"
    } else if (com_name == "Melilla") {
      prov_id <- "52"
    }

    ### Provincia
    for (j in prov_id) {

      if (nchar(j) == 1) j <- paste0("0", j)

      if (j %in% c("33", "07", "39", "28", "30", "31", "26", "51", "52")) {
        search <- paste0(address, "/", i)
      } else {
        search <- paste0(address, i, "/", j, ".html")
      }

      municip_id <- read_html(search) %>%
        html_nodes(xpath = "/html/body/div[2]/main/div[4]/div[1]/div[2]/div[1]/div[3]/select") %>%
        html_children() %>%
        html_attr("id")
      municip_id <- municip_id[!is.na(municip_id)]


      # Municipality
      for (k in municip_id) {

        cat(
          "Getting data for", paste(paste0("y", y), i, j, k, sep = "-"),
          "\n"
        )

        if (nchar(k) == 1) k <- paste0("0", k)

        list_results[[paste(paste0("y", y), i, j, k, sep= "-")]] <- get_data_xml(y, i, j, k)

      }

    }

  }

}


##########
## Create full dataframe ##
##########

final <- data.table::rbindlist(list_results) %>%
  full_join(com_prov_name, by = c("com_index", "prov_index")) %>%
  filter(!is.na(munic)) %>%
  select(-com_index, -prov_index) %>%
  mutate(
    year = as.numeric(year),
    votes = as.numeric(votes),
    share_votes = as.numeric(share_votes),
    elected_members = as.numeric(elected_members),
  )


### Make a few checks by comparing results here with the website
### (take some results randomly)
stopifnot(
  # In Ceuta
  final[year == "2007" & munic == "Ceuta" & party_name == "UDCE-IU CEUTA",
        votes] == 5659,
  # In Madrid
  final[year == "2011" & munic == "Alcobendas" & party_name == "UPyD",
        elected_members] == 5,
  # In Andalucia -> Cordoba
  final[year == "2015" & munic == "Valsequillo" & party_name == "PSOE-A",
        share_votes] == 60.14,
  # In Andalucia -> Jaen
  final[year == "2019" & munic == "Arquillos" & party_name == "PP",
        votes] == 787
)


### Number of municipalities
nrow(unique(final[year == 2007, "munic"])) # 8044
nrow(unique(final[year == 2011, "munic"])) # 8066
nrow(unique(final[year == 2015, "munic"])) # 8068
nrow(unique(final[year == 2019, "munic"])) # 8068



##########
## Write CSV file ##
##########

readr::write_excel_csv(final, "votes_municipality.csv")

