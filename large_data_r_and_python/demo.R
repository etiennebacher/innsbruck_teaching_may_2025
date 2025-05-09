library(arrow)
library(polars)
library(tidyverse)
library(tidypolars)

scanned <- pl$scan_csv("large_data_r_and_python/data_ipums/ipums_samples.csv")

### Get number of rows
scanned |> 
  select(1) |> 
  compute() |> 
  nrow()

### Get number of columns
scanned |> 
  head(1) |> 
  compute() |> 
  ncol()

### Get the schema of the data
scanned$schema

### Get a sample of the data for exploration purposes
read <- scanned |> 
  head(100) |> 
  collect() |> 
  as_tibble()


# View(read)

### Once you want to use the full data, use the scanned version
scanned |> 
  arrange(YEAR) |> 
  filter(STATEFIP %in% c(1, 3, 5)) |> 
  compute()

scanned |> 
  group_by(YEAR, STATEFIP) |> 
  summarize(
    x = mean(OCCSCORE, na.rm = TRUE)
  ) |> 
  arrange(YEAR, STATEFIP) |>
  compute()


system.time({
  scanned |> 
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
  print(
    scanned |> 
      arrange(YEAR) |> 
      filter(STATEFIP %in% c(1, 3, 5)) |> 
      compute()
  )
  
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
    

foo <- data.table::fread("large_data_r_and_python/data_ipums/ipums_samples.csv")
nanoparquet::write_parquet(foo, "large_data_r_and_python/data_ipums/ipums_samples.parquet")

