#####################################################################
## Webscrape election results for municipal elections for all municipalities
#####################################################################

### Ex: https://resultados.elpais.com/elecciones/2019/municipales/01/04/19.html

library(tidyverse)
library(rvest)
library(polite)


### Part 1: get party results for Bacares in 2019

url <- "https://resultados.elpais.com/elecciones/2019/municipales/01/04/19.html"

html <- read_html(url)

html |> 
  html_element("#tablaVotosPartidos") |> 
  html_table() 

### Part 1 bis: being polite

url <- bow("https://resultados.elpais.com/elecciones/2019/municipales/01/04/19.html")

html <- scrape(url)

html |> 
  html_element("#tablaVotosPartidos") |> 
  html_table() 

# Use the argument "delay" to reduce the delay (default is 5 sec) but don't 
# forget to also specify the "user_agent" argument in this case.
url2 <- bow(
  "https://resultados.elpais.com/elecciones/2019/municipales/01/04/19.html",
  user_agent = "teaching-webscraping", 
  delay = 2
)


### Part 2: generalize this to all communities + provinces + municipalities
###
### To build all those combinations, we must first get all values for 
### communities, then get all values for provinces (for each community), then
### get all values for municipalities (for each province)

# ----------------------------------------
# Get all comunidad IDs and names

# Get the selector for "Comunidad" and then select its "children", meaning
# all the possible options in this selector
choices <- scrape(url2) |> 
  html_element("#comboCA") |> 
  html_children()

com_ids <- choices |> 
  html_attr("id")

com_names <- choices |> 
  html_text()

# Clean the ids: 
# - the first choice in the selector doesn't have any id (it's NA) so we drop 
#   that
# - the ids must always have two digits, so we add a trailing 0 for single-digit
#   number 
com_ids <- com_ids[!is.na(com_ids)]
com_ids <- sapply(com_ids, function(x) {
  if (nchar(x) == 1) {
    paste0("0", x)
  } else {
    x
  }
})
com_ids <- unname(com_ids)
com_ids

# Clean the names: 
# - the first choice in the selector is "Comunidad", which is not a real choice
#   so we drop that
com_names <- com_names[com_names != "Comunidad"]
com_names

# Store the results for later
com <- data.frame(com_id = com_ids, com_name = com_names)


# ----------------------------------------
# Get all province IDs and names
# We have to loop through all possible "com_ids"

# Make a list that will store all the dataframes, one per community. At the
# end of the loop, we'll bind them to have a single dataframe with all 
# community-province combinations.
provinces <- list()

for (com_id in com_ids) {
  message("Getting provinces for comunidad ", com_id)
  
  url <- bow(paste0("https://resultados.elpais.com/elecciones/2019/municipales/", com_id))
  
  ### More or less the same scraping and cleaning steps as before
  
  choices <- scrape(url) |> 
    html_element("#comboCIR") |> 
    html_children()
  
  prov_ids <- choices |> 
    html_attr("id")
  
  prov_names <- choices |> 
    html_text()
  
  prov_ids <- prov_ids[!is.na(prov_ids)]
  prov_ids <- sapply(prov_ids, function(x) {
    if (nchar(x) == 1) {
      paste0("0", x)
    } else {
      x
    }
  })
  prov_ids <- unname(prov_ids)
  prov_ids
  
  prov_names <- prov_names[prov_names != "Provincia"]
  prov_names
  
  # It's possible that a community doesn't have any province, in which case
  # prov_names will be empty, so we only return a data.frame when it's not.
  if (length(prov_names) > 0) {
    provinces[[com_id]] <- data.frame(
      com_id = com_id,
      prov_id = prov_ids,
      name = prov_names
    )
  }
}

provinces <- bind_rows(provinces)



# ----------------------------------------
# MISSING PART FROM THE LIVE DEMO
# 
# We have seen that some comunidad have no (or only one provincia), hence the
# second selector was empty. We discarded those cases but we still need to
# include them manually in the list of combinations otherwise they won't be
# scraped.
# 
# The values can be found when doing a search for a municipality. For
# instance, select "Madrid" in the community selector and "Ajalvir" in the
# municipality selector (3rd one) and you'll see that the URL ends with
# 12/28/02, so 12 is the com_id and 28 is the prov_id, and this doesn't
# change for all municipalities in Madrid. 
# 
# I create this dataframe manually and bind it to the one we generated 
# automatically.

missing_combs <- data.frame(
  com_id = c("03", "04", "06", "12", "15", "13", "16", "18", "19"),
  prov_id = c("33", "07", "39", "28", "30", "31", "26", "51", "52"),
  name = c("Asturias", "Baleares", "Cantabria", "Madrid", "Murcia", "Navarra", "La Rioja", "Ceuta", "Melilla")
)

provinces <- bind_rows(provinces, missing_combs)


# ----------------------------------------
# Get all municipality IDs and names
# We have to loop through all possible combinations of community-province stored
# in the "provinces" dataframe we created above.

municipalities <- list()

for (row in 1:nrow(provinces)) {
  
  com_id <- provinces[row, "com_id"]
  prov_id <- provinces[row, "prov_id"]
  
  message("Getting municipalities for comunidad ", com_id, " and province ", prov_id)
  
  url <- bow(paste0("https://resultados.elpais.com/elecciones/2019/municipales/", com_id, "/", prov_id, ".html"))
  
  choices <- scrape(url) |> 
    html_element("#comboMUN") |> 
    html_children()
  
  mun_ids <- choices  |> 
    html_attr("id")
  
  mun_names <- choices |> 
    html_text()
  
  mun_ids <- mun_ids[!is.na(mun_ids)]
  mun_ids <- sapply(mun_ids, function(x) {
    if (nchar(x) == 1) {
      paste0("0", x)
    } else {
      x
    }
  })
  mun_ids <- unname(mun_ids)
  mun_ids
  
  mun_names <- mun_names[mun_names != "Municipio"]
  mun_names
  
  if (length(mun_names) > 0) {
    municipalities[[row]] <- data.frame(
      com_id = com_id,
      prov_id = prov_id,
      mun_id = mun_ids,
      mun_name = mun_names
    )
  }
}

municipalities <- bind_rows(municipalities)


# --------------------------------------
# Get table for each municipality
# 
# We now have all the combinations of community-province-municipality, so we
# can build all URLs to scrape.
# 
# WARNING: this may take a while, you probably want to let it run 1min for the
# demo

results <- list()

for (row in 1:nrow(municipalities)) {
  
  com_id <- municipalities[row, "com_id"]
  prov_id <- municipalities[row, "prov_id"]
  mun_id <- municipalities[row, "mun_id"]
  
  message("Getting table for comunidad ", com_id, ", province ", prov_id, " and municipality ", mun_id)
  
  url <- bow(paste0("https://resultados.elpais.com/elecciones/2019/municipales/", com_id, "/", prov_id, "/", mun_id, ".html"))
  
  res <- scrape(url) |> 
    html_element("#tablaVotosPartidos") |> 
    html_table()
  
  res[["com_id"]] <- com_id
  res[["prov_id"]] <- prov_id
  res[["mun_id"]] <- mun_id
  
  if (length(res) > 0) {
    results[[row]] <- res
  }
}

bind_rows(results)


