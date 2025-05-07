library(arrow)
library(polars)
library(tidyverse)
library(tidypolars)

# Files obtained from https://www2.census.gov/programs-surveys/popest/datasets/2020/modified-race-data/

# for (i in 1:56) {
#   i <- sprintf("%02d", i)
#   tryCatch({
#     download.file(sprintf("https://www2.census.gov/programs-surveys/popest/datasets/2020/modified-race-data/MARC2020-County-%s.csv", i), destfile = sprintf("large_data_r_and_python/data/MARC2020-County-%s.csv", i))
#   },
#   error = function(e) {
#     message("Couldn't download file ", i)
#   })
# }

# download.file("https://www2.census.gov/programs-surveys/popest/datasets/2020/modified-race-data/MARC2020-County-US.csv", destfile = "large_data_r_and_python/data/MARC2020-County-%s.csv")

subset <- pl$scan_csv("large_data_r_and_python/data/MARC2020-County-US.parquet")$
  head(100)$
  collect()$
  to_data_frame()

subset <- pl$scan_parquet("large_data_r_and_python/data3/ipums.parquet")$
  head(100)$
  collect()$
  to_data_frame()

pl$read_csv("large_data_r_and_python/data_ipums/ipums_samples.csv") |> 
  dim()

system.time({
  pl$scan_csv("large_data_r_and_python/data_ipums/ipums_samples.csv") |> 
    # head(100) |> 
    # as_tibble() |>  
    group_by(YEAR, STATEFIP) |> 
    summarize(
      x = mean(OCCSCORE, na.rm = TRUE)
    ) |> 
    arrange(YEAR, STATEFIP) |>
    compute()
})

system.time({
  arrow::open_csv_dataset("large_data_r_and_python/data_ipums/ipums_samples.csv") |> 
    # head(100) |> 
    # as_tibble() |>  
    group_by(YEAR, STATEFIP) |> 
    summarize(
      x = mean(OCCSCORE, na.rm = TRUE)
    ) |> 
    arrange(YEAR, STATEFIP) |>
    collect()
})

system.time({
  read_csv_duckdb("large_data_r_and_python/data_ipums/ipums_samples.csv") |> 
    # head(100) |> 
    # as_tibble() |>  
    summarize(
      x = mean(OCCSCORE, na.rm = TRUE),
      .by = c(YEAR, STATEFIP)
    ) |> 
    arrange(YEAR, STATEFIP) |>
    collect()
})


system.time({
  scan_parquet_polars("large_data_r_and_python/data3/ipums.parquet") |> 
    summarize(
      ocscorus_mean = mean(ocscorus, na.rm = TRUE),
      .by = c(year, countyus, sex, race)
    ) |>
    compute()
  
})

system.time({
  arrow::open_dataset("large_data_r_and_python/data3/ipums.parquet") |> 
    summarize(
      ocscorus_mean = mean(ocscorus, na.rm = TRUE),
      .by = c(year, countyus, sex, race)
    ) |> 
    collect()
  
})

system.time({
  nanoparquet::read_parquet("large_data_r_and_python/data3/ipums.parquet") |> 
    summarize(
      ocscorus_mean = mean(ocscorus, na.rm = TRUE),
      .by = c(year, countyus, sex, race)
    ) 
})
    

foo <- data.table::fread("large_data_r_and_python/data3/ipums.csv")
nanoparquet::write_parquet(foo, "large_data_r_and_python/data3/ipums.parquet")
