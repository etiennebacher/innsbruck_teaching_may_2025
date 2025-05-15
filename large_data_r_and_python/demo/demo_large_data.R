library(polars)
library(tidyverse)
library(tidypolars)

### Package "polars": almost identical to the code in Python. You need
### to replace the "." by "$", and a couple of other things (e.g.
### "True" in Python is "TRUE" in R).
ipums <- pl$scan_parquet("data_ipums/ipums_samples.parquet")
print(ipums)
print(ipums$schema)

ipums_small <- ipums$head(100)$collect()
ipums_small 

ipums$
  group_by("STATEFIP", "YEAR")$
  agg(mean_occscore<-pl$col("OCCSCORE")$mean())$
  with_columns(a = 1)$
  with_columns(b = pl$col("a") + 1)$
  collect()

standardize <- function(x) {
  ((x - x$mean()) / x$std())$over("YEAR")
}

ipums$
  with_columns(occscore_stand = standardize(pl$col("OCCSCORE")))$
  collect()


### Package "tidypolars": useful if you're used to the tidyverse syntax
ipums <- scan_parquet_polars("data_ipums/ipums_samples.parquet")

output <- ipums |> 
  group_by(STATEFIP, YEAR) |> 
  summarize(mean_occscore = mean(OCCSCORE, na.rm = TRUE)) |> 
  mutate(
    a = 1,
    b = a + 1
  ) |> 
  compute()

