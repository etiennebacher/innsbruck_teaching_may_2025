#####################################################################
## Webscrape election results for municipal elections for all municipalities
#####################################################################

### Ex: https://resultados.elpais.com/elecciones/2019/municipales/01/04/19.html

library(tidyverse)
library(rvest)
library(xml2)
library(janitor)


### Part 1: get party results for Bacares in 2019

url <- "https://resultados.elpais.com/elecciones/2019/municipales/01/04/19.html"

html <- read_html(url)

html |> 
  html_element("h1") |> 
  html_text()

html |> 
  html_element("#tablaVotosPartidos") |> 
  html_table() |> 
  clean_names()



### Part 2: generalize this to all provinces + departments + municipalities

# URL: first number is comunidad, second one is province, third one is
# municipality

# Problem: the values for province depend on the comunidad, and the values
# for municipality depend on the province

# Also: we want the name of the place + their id on the website

# Get name and index for comunidad

com_id <- c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11",
            "12", "13", "14", "15", "16", "17", "18", "19")
address <- "https://resultados.elpais.com/elecciones/2019/municipales/"

com_info <- read_html(address) |>
  html_element("#comboCA") |>
  html_children()

com_info |>
  html_attr("id")

com_info |>
  html_text()

com_name <- data.frame(
  com_index = com_info |>
    html_attr("id"),
  comunidad = com_info |>
    html_text()
) |>
  filter(comunidad != "Comunidad") |>
  mutate(com_index = ifelse(nchar(com_index) == 1,
                            paste0("0", com_index),
                            com_index))


### Get name and index for province

prov_name <- list()
for (i in com_id) {
  
  message("Getting provinces for comunidad ", i)
  
  # Get names
  choices <- read_html(paste0(address, i)) |>
    html_element("#comboCIR") |>
    html_children()
  
  names_prov <- html_text(choices)
  id_prov <- html_attr(choices, "id")
  id_prov <- id_prov[!is.na(id_prov)]
  
  # Remove placeholder
  names_prov <- names_prov[names_prov != "Provincia"]
  if (length(names_prov2) == 0) {
    names_prov2 <- "Single provincia"
    id_prov <- NA
  } 

  prov_name[[paste0("id", i)]] <- data.frame(
    comunidad = i,
    prov_index = id_prov,
    provincia = names_prov
  )
}

prov_name <- data.table::rbindlist(prov_name)


### Merge index and names for comunidad and provincia

com_prov_name <- left_join(
  com_name,
  prov_name,
  by = c("com_index" = "comunidad")
) |>
  mutate(provincia = ifelse(comunidad %in% c("Melilla", "Ceuta"),
                            "Not provincia",
                            provincia),
         prov_index = ifelse(nchar(prov_index) == 1,
                             paste0("0", prov_index),
                             prov_index))

# Note : 50 comunidad (7 of which are made of a single province), 2 are not comunidad (Melilla and Ceuta)


### We have info on the list of comunidad + province.
### Now we can go on each page, get the list of municipalities.

municip_name <- list()
for (row in 1:nrow(com_prov_name)) {
  com_id <- com_prov_name[row, "com_index"]
  prov_id <- com_prov_name[row, "prov_index"]
  message("Getting municipalities for comunidad ", com_id, " and province ", prov_id)
  
  prov_url <- paste0(
    "https://resultados.elpais.com/elecciones/2019/municipales/", 
    com_id, "/", prov_id, ".html"
  )
  municip_selector <- read_html(prov_url) |> 
    html_element("#comboMUN") |>
    html_children() 
  
  municip_ids <- html_attr(municip_selector, "id")
  municip_names <- html_text(municip_selector)
  
  municip_ids <- municip_ids[!is.na(municip_ids)]
  municip_names <- municip_names[municip_names != "Municipio"]
  
  municip_name[[paste0("id", i)]] <- data.frame(
    com_index = com_id,
    prov_index = prov_id,
    municip_index = municip_ids,
    municip = municip_names
  )
}

municip_name



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


