import polars as pl

raw_data = pl.scan_parquet("foo.parquet")


my_data = (raw_data
   .sort("iso")
   .filter(
      pl.col("gdp") > 123,
      pl.col("country").is_in(["United Kingdom", "Japan", "Vietnam"])
   )
   .with_columns(gdp_per_cap = pl.col("gdp") / pl.col("population")).explain(optimized=False))

print(my_data)
