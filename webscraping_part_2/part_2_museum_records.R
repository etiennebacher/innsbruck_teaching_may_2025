library(dplyr)
library(rvest)
library(RSelenium)
library(logger)

# Save messages in a log file
log_appender(appender_file("data/modals/00_logfile"))
log_messages()

# Create folder where HTML files will be stored if it doesn't already exist
if (!dir.exists("data")) {
  dir.create("data")
}
if (!dir.exists("data/modals")) {
  dir.create("data/modals")
}

# Initiate RSelenium
link <- "https://www.acervodigital.museudaimigracao.org.br/livros.php"
driver <- rsDriver(
  browser = "firefox", 
  chromever = NULL,
  extraCapabilities = list(acceptInsecureCerts = TRUE)
) 
remote_driver <- driver[["client"]]

# Go the website
remote_driver$navigate(link)

# Wait for the website to load
Sys.sleep(3)


# Fill the nationality field and click on "Validate"
remote_driver$
  findElement(using = "id", value = "nacionalidade")$
  sendKeysToElement(list("PORTUGUESA"))

remote_driver$
  findElement(using = 'name', value = "Reset2")$
  clickElement()


# Make the list of elements
buttons <- remote_driver$findElements(using = 'id', value = "link_ver_detalhe")

# Highlight each button one by one
for (i in seq_along(buttons)) {
  buttons[[i]]$highlightElement()
  Sys.sleep(1)
}

# Download all the modals on the page (you don't have to run this since
# we also scrape the first page in the other loop below).
for (i in seq_along(buttons)) {
  # open the modal
  buttons[[i]]$clickElement()
  Sys.sleep(1)
  
  # get the HTML and save it
  tmp <- remote_driver$getPageSource()[[1]]
  write(tmp, file = paste0("webscraping_part_2/data/modals/modal-", i, ".html"))
  
  # quit the modal (by pressing "Escape")
  remote_driver$findElement(
    using = "xpath",
    value = "/html/body"
  )$sendKeysToElement(list(key = "escape"))
}


# Two loops: for all individuals on a page, and for all pages, open the modal
# and get the page source

for (page_index in 1:3) {

  message("Start scraping of page ", page_index)

  buttons <- remote_driver$
    findElements(using = 'id', value = "link_ver_detalhe")

  for (modal_index in seq_along(buttons)) {

    tryCatch(
      {
        # open modal
        buttons[[modal_index]]$clickElement()

        Sys.sleep(1.5)

        # Get the HTML and save it
        tmp <- remote_driver$getPageSource()[[1]]
        write(tmp, file = paste0("data/modals/page-", page_index, "-modal-", modal_index, ".html"))

        # Leave the modal
        body <- remote_driver$findElement(using = "xpath", value = "/html/body")
        body$sendKeysToElement(list(key = "escape"))

        message("  Scraped modal ", modal_index)
      },
      error = function(e) {
        message("  Failed to scrape modal ", modal_index)
        message("  The error was ", e)
        next
      }
    )

    Sys.sleep(1.5)

  }

  # When we got all modals of one page, go to the next page (except if
  # we're on the last one)
  if (page_index != 2348) {
    # Give selenium a bit of time to actually find the
    # element before clicking it
    elem <- remote_driver$findElement("id", as.character(page_index + 1))
    Sys.sleep(1)
    elem$clickElement()
  }

  message("Finished scraping of page ", page_index)

  # Wait a bit for page loading
  Sys.sleep(5)
}



### Clean the HTML

# Explore for one or two pages
raw_html <- read_html("data/modals/page-1-modal-1.html")
tables <- raw_html |> 
  html_element("#detalhe_conteudo") |> 
  html_table()

tables[1:14, ]
tables[16:20, ]

raw_html <- read_html("data/modals/page-1-modal-20.html")
tables <- raw_html |> 
  html_element("#detalhe_conteudo") |> 
  html_table()

tables[1:14, ]
tables[16:20, ]

# Function to clean the HTML for each individual
clean_modal <- function(path_modal) {
  raw_html <- read_html(path_modal)
  
  tables <- raw_html |> 
    html_element("#detalhe_conteudo") |> 
    html_table()
  
  basic_info <- tables[1:14, ]
  relations <- tables[16:20, ]
  
  list(
    basic_info = basic_info,
    relations = relations
  )
}

# List all HTML files we saved
all_modals <- list.files(
  "data/modals",
  pattern = "html",
  full.names = TRUE
)

# Clean the first 10
lapply(all_modals[1:10], clean_modal)
