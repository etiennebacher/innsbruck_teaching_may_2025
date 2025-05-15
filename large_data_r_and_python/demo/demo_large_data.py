import polars as pl

# Get the data in lazy mode. Printing this only shows the source of the data.
# We can also get the schema (i.e. column names + column data types).
ipums = pl.scan_parquet("data_ipums/ipums_samples.parquet")
print(ipums)
print(ipums.collect_schema())

# Create a variable that only contains the first 100 rows.
# This is useful to see what the data looks like and do some quick tests. However,
# it might be better to use filter() so that you can get data for a single US state
# for instance.
ipums_small = ipums.head(100).collect()
ipums_small

# We can chain several functions and Polars will take care of optimizing the order.
# with_columns() allows us to create an additional column.
ipums_alabama = (
    ipums.filter(pl.col("STATEFIP") == 1)
    .sort(pl.col("COUNTYNHG"))
    .with_columns(mean_occscore=pl.col("OCCSCORE").mean())
    .collect()
)
ipums_alabama

# We also could have created several intermediate variables, and call collect() only
# at the very end.
ipums_alabama = ipums.filter(pl.col("STATEFIP") == 1).sort(pl.col("COUNTYNHG"))

ipums_alabama_with_mean_occscore = ipums_alabama.with_columns(
    mean_occscore=pl.col("OCCSCORE").mean()
)

ipums_alabama_with_mean_occscore.collect()

# To compute some aggregations, use group_by() + agg().
# Note that the output is not returned in the same group order as how they appear in
# the data.
# If you want to keep the same order, use maintain_order=True in group_by() (this is
# a bit slower however).
ipums.group_by("STATEFIP", "YEAR").agg(
    mean_occscore=pl.col("OCCSCORE").mean()
).collect()

# So far we use "common" expressions, such as mean().
# Polars contains many more expressions and stores some of them in separate namespace,
# such as "str" for functions applicable on character columns.

# There isn't any character columns in the data so I create one here.
with_text = ipums.select(text=pl.lit("Etienne")).collect()
with_text

# I can use character-specific functions with the "str" prefix. Note that you need
# to add this prefix before every character-specific function, like below:
with_text.with_columns(contains_e=pl.col("text").str.to_uppercase().str.contains("E"))

# We need to separate with_columns() statements if we create several variables that
# depend on each other.
# The code that is commented out below would error:
# ipums.with_columns(a=1, b=pl.col("a") + 1).collect()
#
# Polars runs all expressions in with_columns() in parallel so column "a" doesn't
# exist yet when the expression for "b" runs.
#
# Instead, we need to split those in separate with_columns():
ipums.with_columns(a=1).with_columns(b=pl.col("a") + 1).collect()

# Expressions can be used in other contexts, not only with_columns().
# For instance, we could use them in filter():
ipums_alabama.filter(pl.col("OCCSCORE") >= pl.col("OCCSCORE").mean()).collect()

ipums_alabama.filter(
    (pl.col("OCCSCORE") >= pl.col("OCCSCORE").mean().over("YEAR"))
).collect()

# Exporting data can be done with the write_*() functions, such as write_parquet():
ipums_alabama.filter(
    (pl.col("OCCSCORE") >= pl.col("OCCSCORE").mean().over("YEAR"))
).collect().write_parquet("data_ipums/alabama.parquet")


# Create a custom function to standardize numeric variables
def standardize(x) -> pl.Expr:
    # The "return" keywords has to be specified (contrarily to R)
    return ((x - x.mean()) / x.std()).over("YEAR")


# Apply this custom function in with_columns()
ipums_alabama.with_columns(occscore_stand=standardize(pl.col("OCCSCORE"))).collect()

# If the function you want to use doesn't exist in Polars and cannot be easily rewritten
# with Polars syntax, you can use:
# - map_batches(): this will take the column as a whole, which can be necessary for instance
#                  if you use aggregations in the function (e.g. if you use the mean of the
#                  column to compute the output).
# - map_elements(): this will take each value in the column one-by-one, so don't use it if
#                   you need aggregations to compute the output.

ipums_alabama.with_columns(
    occscore_stand=pl.col("OCCSCORE")
    .map_batches(lambda x: (x - x.mean()) / x.std())
    .over("YEAR")
).collect()
