library(rvest)
library(tidyverse)

library(polite)

url <- "https://resultados.elpais.com/elecciones/2019/municipales/01/04/19.html"

html <- read_html(url)

html |> 
  html_element("#tablaVotosPartidos") |> 
  html_table()

# ----------------------------------------

url2 <- bow(url, user_agent = "teaching-webscraping", delay = 2)
scrape(url2) |> 
  html_element("#tablaVotosPartidos") |> 
  html_table()

# ----------------------------------------
# Get all comunidad IDs and names

choices <- scrape(url2) |> 
  html_element("#comboCA") 

ids <- choices |> 
  html_children() |> 
  html_attr("id")

ids <- ids[!is.na(ids)]

# Add a leading 0 if necessary
ids <- sapply(ids, function(x) {
  if (nchar(x) == 1) {
    paste0("0", x)
  } else {
    x
  }
})
ids <- unname(ids)
ids


com_names <- choices |> 
  html_children() |> 
  html_text()

com_names <- com_names[com_names != "Comunidad"]
com_names


com <- data.frame(
  id = ids,
  name = com_names
)


# ----------------------------------------
# Get all province IDs and names

provinces <- list()

for (com_id in ids) {
  message("Getting provinces for comunidad ", com_id)
  
  url <- bow(paste0("https://resultados.elpais.com/elecciones/2019/municipales/", com_id))
  
  choices <- scrape(url) |> 
    html_element("#comboCIR") 
  
  prov_ids <- choices |> 
    html_children() |> 
    html_attr("id")
  
  prov_ids <- prov_ids[!is.na(prov_ids)]
  
  # Add a leading 0 if necessary
  prov_ids <- sapply(prov_ids, function(x) {
    if (nchar(x) == 1) {
      paste0("0", x)
    } else {
      x
    }
  })
  prov_ids <- unname(prov_ids)
  prov_ids
  
  prov_names <- choices |> 
    html_children() |> 
    html_text()
  
  prov_names <- prov_names[prov_names != "Provincia"]
  prov_names
  
  if (length(prov_names) > 0) {
    provinces[[com_id]] <- data.frame(
      com_id = com_id,
      id = prov_ids,
      name = prov_names
    )
  }
}

provinces <- bind_rows(provinces)


# ----------------------------------------
# Get all municipality IDs and names

municipalities <- list()

for (row in 1:nrow(provinces)) {
  
  com_id <- provinces[row, "com_id"]
  prov_id <- provinces[row, "id"]
  
  message("Getting municipalities for comunidad ", com_id, " and province ", prov_id)
  
  url <- bow(paste0("https://resultados.elpais.com/elecciones/2019/municipales/", com_id, "/", prov_id, ".html"))
  
  choices <- scrape(url) |> 
    html_element("#comboMUN") 
  
  mun_ids <- choices |> 
    html_children() |> 
    html_attr("id")
  
  mun_ids <- mun_ids[!is.na(mun_ids)]
  
  # Add a leading 0 if necessary
  mun_ids <- sapply(mun_ids, function(x) {
    if (nchar(x) == 1) {
      paste0("0", x)
    } else {
      x
    }
  })
  mun_ids <- unname(mun_ids)
  mun_ids
  
  mun_names <- choices |> 
    html_children() |> 
    html_text()
  
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
