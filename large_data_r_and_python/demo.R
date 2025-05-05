library(neopolars)
library(tidyverse)
library(tidypolars)

# l <- list.files("/media/etienne/LaCie/Dossiers/LISER/Divers/LISER/these/these-UK-US-linking/data/temp", full.names = TRUE)[1:10]

# dims <- c()
# for (i in seq_along(l)) {
#   print(i)
#   x <- pl$read_csv(l[i], ignore_errors = TRUE)
#   dims <- c(dims, nrow(x))
#   remove(x)
# }

system.time({
  pl$scan_csv(
    "/media/etienne/LaCie/Dossiers/LISER/Divers/LISER/these/these-UK-US-linking/data/temp/Texas_TX.csv",
    ignore_errors = TRUE
  )$group_by("SUMLEV")$agg(pl$col("P0030015")$sum())$collect()
})

system.time({
  pl$scan_csv(
    "/media/etienne/LaCie/Dossiers/LISER/Divers/LISER/these/these-UK-US-linking/data/temp/Texas_TX.csv",
    ignore_errors = TRUE
  )$group_by("SUMLEV")$agg(pl$col("P0030015")$sum())$collect(streaming = TRUE)
})

system.time({
  scan_csv_polars(
    "/media/etienne/LaCie/Dossiers/LISER/Divers/LISER/these/these-UK-US-linking/data/temp/Texas_TX.csv"
  ) |>
    group_by(SUMLEV) |>
    summarize(P0030015 = sum(P0030015, na.rm = TRUE)) |>
    compute()
})

system.time({
  read_csv(
    "/media/etienne/LaCie/Dossiers/LISER/Divers/LISER/these/these-UK-US-linking/data/temp/Texas_TX.csv"
  ) |>
    group_by(SUMLEV) |>
    summarize(P0030015 = sum(P0030015))
})
