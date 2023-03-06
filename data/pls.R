# Load the seminr package
library(seminr)

adapt_data = read.csv("data.csv")
# Measurement Model
adapt_mm <- constructs(
  composite("AdaptableSW", multi_items("SWADAPT", 1:7)),
  composite("CodeAdaptabilty", multi_items("CODEADAPT", 1:5))
)
# Structural Model
adapt_sm <- relationships(
  paths(from = "CodeAdaptabilty", to = "AdaptableSW")
)

adapt_pls <- estimate_pls(data = adapt_data,
                          measurement_model = adapt_mm,
                          structural_model = adapt_sm)

plot(adapt_pls, title = "Estimated Model")