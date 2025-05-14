import polars as pl
import time

ipums_data = pl.scan_csv("../data_ipums/ipums_samples.csv")
# start = time.time()
# print(
#     ipums_data.group_by("YEAR", "STATEFIP")
#     .agg(mean_occscore=pl.col("OCCSCORE").mean())
#     .filter(pl.col("YEAR") == 1900)
#     .collect()
# )
# end = time.time()
# print(f"Time taken: {end - start}")


def standardize(x) -> pl.Expr:
    return (x - x.mean()) / x.std()


start = time.time()
print(
    ipums_data.with_columns(
        occscore_stand=standardize(pl.col("OCCSCORE")).over("YEAR", "STATEFIP")
    )
    .filter(pl.col("YEAR") == 1900, pl.col("STATEFIP") == 1)
    .collect()
)
end = time.time()
print(f"Time taken: {end - start}")
