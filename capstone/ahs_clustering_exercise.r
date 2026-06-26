# Spatial Clustering of Infant Mortality Rate in EAG Sttes


# The steps involved in the clustering analysis are as follows:
# - Filtering the AHS data for the Infant Mortality Rate indicator.
# - Creating spatial weights to measure spatial relationships between districts.
# - Computing Local Moran's I statistics to identify spatial clustering patterns.
# - Assigning colors to different types of clustering patterns.
# - Creating cluster labels and categorizing the clusters.
# - Adding the clustering information to the spatial data.
# - Plotting the districts colored by the identified clustering patterns.

# Load required libraries
pacman::p_load(tidyverse,  # For data manipulation and visualization
               here,       # For managing file paths
               sf,         # For handling spatial data
               rgeoda,     # LISA Statistics
               spdep,      # Global Moran's Statistics
               patchwork,  # For organizing multiple plots
               mapview,    # Interactive Visualizations
               RColorBrewer# Color Palettes
               )

sf_use_s2(FALSE)

# Load the AHS data
ahs_joined_sf <- read_rds(here('data', 'ahs_joined_sf.rds'))

# Check CRS
ahs_joined_sf |>
  st_crs()

# CLUSTERING OF DISTRICTS WITH HIGH PROPORTION OF IMR (AHS 2010-11)

######################################################
# GLOBAL CLUSTERING
######################################################

# Let us check for global clustering using `spdep` package
imr_sf <- ahs_joined_sf |>
  select(state, district, unique_district, infant_mortality_rate_imr_2010_11)

# STEP ONE: Define neighboring polygons
# Define the neighbors using the Queen contiguity criterion
nb <- poly2nb(imr_sf, queen=TRUE)

# STEP TWO: Assign weights to the neighbors
# Create a weights list with a binary (0/1) weight scheme
lw <- nb2listw(nb, style="W", zero.policy=TRUE)
lw$weights

# STEP THREE: Compute the (weighted) neighbor mean values
# Estimate the spatial lag for each district
imr_sf <- imr_sf |>
  mutate(spatial_lag = lag.listw(lw, imr_sf$infant_mortality_rate_imr_2010_11))

# STEP FOUR: Plot Moran's Scatter Plot
# Moran's Scatter Plot shows the relationship between IMR and its spatial lag
imr_sf |>
  ggplot(aes(x = infant_mortality_rate_imr_2010_11, y = spatial_lag)) +
  geom_point() +
  geom_smooth(method = "lm")

spdep::moran.plot(imr_sf$infant_mortality_rate_imr_2010_11, lw)

# OLS Regression to estimate the slope of the Moran's Scatter Plot
ols_model <- lm(spatial_lag ~ infant_mortality_rate_imr_2010_11, data = imr_sf)
coef(ols_model)[2]

# STEP FIVE: Compute the Moran’s I statistic
# Moran's I statistic measures spatial autocorrelation
moran(imr_sf$infant_mortality_rate_imr_2010_11, lw, length(nb), Szero(lw))

# STEP SIX: Perform a Hypothesis Test
# Test the hypothesis that IMR is randomly distributed across districts

# 6a: ANALYTICAL Method
# Perform Moran's I test using the analytical method
moran.test(imr_sf$infant_mortality_rate_imr_2010_11, lw, alternative="greater")

# 6b: MONTE CARLO Method
# Run Monte Carlo simulation to test Moran's I statistic
set.seed(1234)
mc_moran <- moran.mc(imr_sf$infant_mortality_rate_imr_2010_11, lw, nsim=9999, alternative="greater")

# 6c: Plot the results
# Plot the null distribution of Moran's I values
plot(mc_moran)
# Interpretation: The observed statistic (0.53693) is significantly higher than expected, indicating clustering.

# 6d: Display the resulting statistics
# Print the results of the Monte Carlo simulation
mc_moran



######################################################
# LOCAL CLUSTERING
######################################################

# Load necessary libraries for local clustering
library(rgeoda)  # For local spatial analysis

# STEP ONE: Create Spatial Weights
# Create a spatial weights object using Queen contiguity
queen_w <- queen_weights(imr_sf)

# STEP TWO: Perform Local Moran's I Analysis
# Compute Local Moran's I statistics for IMR data
lisa <- local_moran(queen_w, imr_sf["infant_mortality_rate_imr_2010_11"])

# Define color schemes for visualization based on Local Moran's I results
lisa_colors <- lisa_colors(lisa)

# Define labels and clusters from Local Moran's I results
lisa_labels <- lisa_labels(lisa)
lisa_clusters <- lisa_clusters(lisa)
lisa_pvals <- lisa_pvalues(lisa)
lisa_vals <- lisa_values(lisa)

# Create factor labels for clustering based on Local Moran's I results
lisa_labs <- factor(lisa_clusters, levels = 0:(length(lisa$labels)-1), labels = lisa$labels)

# Add Local Moran's I results to the spatial data
clustering_sf <- imr_sf |>  bind_cols(lisa_clusters = lisa_clusters,
                                           lisa_labs = lisa_labs,
                                           lisa_pvals = lisa_pvals,
                                           lisa_vals = lisa_vals)

# STEP THREE: Categorize P-values
# Categorize p-values for plotting significance
clustering_sf <- clustering_sf |>
  mutate(lisa_pvals_cat = case_when(
    lisa_pvals <= 0.001 ~ "p <= 0.001",
    lisa_pvals <= 0.01 ~ "p <= 0.01",
    lisa_pvals <= 0.05 ~ "p <= 0.05",
    TRUE ~ "Not Significant",
    is.na(lisa_pvals) ~ NA_character_
  ))

# Define colors for p-value categories
pval_colors <- c("#eeeeee", "#1b7837", "#a6dba0", "#d9f0d3")

# STEP FOUR: Create Plots
# Create plot showing local clustering results
p_hs <- clustering_sf  |>
  ggplot() +
  geom_sf(aes(fill = lisa_labs), lwd=0.2) +
  scale_fill_manual(name = "Clustering", values = lisa_colors) +
  theme_bw()

# Create plot showing p-value categories
p_pval <- clustering_sf  |>
  ggplot() +
  geom_sf(aes(fill = lisa_pvals_cat), lwd=0.2) +
  scale_fill_manual(name = "Local Moran's P Value", values = pval_colors) +
  theme_bw()

# STEP FIVE: Combine the Plots
# Combine the two plots into one figure for comparison
p_imr <- (p_hs + p_pval) +
  plot_layout(ncol = 2, guides = "collect") +
  plot_annotation(title = "Spatial Clustering of Infant Mortality Rate (IMR) among EAG states in 2010-11",
                  caption = "Data Source: Annual Health Survey (AHS) 2010-11 \nhttps://community.data.gov.in/annual-health-survey-ahs-unit-level-data-now-available-on-ogd-platform/",
                  theme = theme(plot.title = element_text(hjust = 0.5, size = 20)))

# Display the combined plot
p_imr

# Save the final plot to a file
fs::dir_create(here("plots"))
ggsave(here("plots", "clustering_imr_plot.png"), width = 9, height = 6)

# Interactive Visualization
mapview(clustering_sf, zcol = "lisa_labs", col.regions=brewer.pal(5, "Greens")) +
mapview(clustering_sf, zcol = "lisa_pvals_cat", col.regions=brewer.pal(4, "Reds"))
######################################################################

# Can you try it for the rest of the indicators?
