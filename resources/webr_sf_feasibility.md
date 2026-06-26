# webR + sf feasibility for live cells (Session-III)

Question: can we run live, in-browser R cells (webR, embeddable in Moodle as GitHub Pages
iframes) for the spatial functions taught in this module? Checked against the webR default
binary repository (repo.r-wasm.org), June 2026.

## Verdict

- **sf works in webR.** `sf` and its geospatial stack (GDAL, GEOS, PROJ compiled to
  WebAssembly) are in the default webR repo. So the core Session-III content (Simple Features,
  CRS, `st_transform`, `geom_sf`) can be live.
- **The ESDA/clustering and extraction packages do not.** `spdep`, `rgeoda`, `exactextractr`,
  `raster`, `tidygeocoder`, `leaflet`, `mapview` are absent from the default repo. Those demos
  stay static (render-time R chunks or shown code).

## Package availability (default webR repo)

| Available | Not available (default repo) |
|-----------|------------------------------|
| `sf`, `terra`, `units`, `classInt` | `spdep`, `rgeoda` |
| `ggplot2`, `dplyr`, `tidyverse`, `sp` | `exactextractr`, `raster` |
| | `tidygeocoder`, `leaflet`, `mapview`, `spData` |

Note: r-universe builds wasm binaries for all CRAN packages, so an absent package can sometimes
be installed by pointing `webr::install()` at an r-universe repo. This is fragile (missing
dependencies, version drift) and is not recommended for teaching cells. Treat the table above
as the reliable set.

## What this means for Session-III (Intro to sf)

**Live webR cells (reliable):**

- Create features from coordinates: `st_as_sf(df, coords = c("lon","lat"), crs = 4326)`
- Inspect: `class()`, `st_crs()`, `st_bbox()`, print an `sf` object
- Reproject: `st_transform(x, 32643)` and compare
- Geometry types and simple ops: `st_centroid`, `st_area` (with `units`)
- Plot: `ggplot() + geom_sf()`
- Packages to preload: `packages: ['sf', 'ggplot2']`

**Keep static (render-time chunks, not webR):**

- Raster extraction (Exercise 3): `exactextractr` / `raster` absent.
- Geocoding (Exercise 4): `tidygeocoder` absent, and it needs network APIs anyway.
- ESDA clustering, Moran's I / LISA (Exercise 7): `spdep`, `rgeoda` absent. This is why the
  Session-II Moran's I demo is hand-coded base R, and why LISA stays in the later session.
- Interactive maps: `leaflet`, `mapview` absent (use a static `geom_sf` map instead).

## Two practical caveats

1. **Data in the browser.** webR has its own virtual filesystem. A live `st_read()` needs the
   file fetched into that filesystem first. Use **small** data for live cells: a few-feature
   GeoJSON, or build geometry from a small coordinate table inline. Do not load the 18 MB India
   shapefile into a live cell.
2. **First-load cost.** `sf` plus the GDAL stack is a large download (tens of MB), fetched on
   first use per session. Acceptable for a lesson page, but preload it and tell learners the
   first cell takes a few seconds. Subsequent cells are fast.

## Tooling choice

- **quarto-webr** (already installed here): simple `{webr-r}` cells. Good for demos.
- **quarto-live** (r-wasm official): adds graded **exercises and quizzes** with webR, plus
  hints and checks. Better fit if we want in-page self-check questions, which the user asked
  about. Worth adopting for Session-III if quizzes are wanted in-page (Moodle XML banks remain
  the summative path).

## Recommendation for Session-III

1. Use live webR cells for the sf fundamentals above, with small inline/GeoJSON data and
   `packages: ['sf', 'ggplot2']`.
2. Keep raster, geocoding, and clustering as static chunks; say in the slide why (package not
   yet built for the browser).
3. If we want in-page quizzes, switch Session-III to **quarto-live** rather than quarto-webr.
4. Test one live sf cell end to end on GitHub Pages and in a Moodle iframe before building the
   full deck, to confirm load time is acceptable on the training network.

## Sources

- webR, installing R packages: https://docs.r-wasm.org/webr/latest/packages.html
- webR default repo package list (`repo-packages`): https://github.com/r-wasm/webr-repo/blob/main/repo-packages
- r-universe builds wasm binaries for all packages (rOpenSci): https://ropensci.org/blog/2023/11/17/runiverse-wasm/
- quarto-webr FAQ (per-session install, `packages` option): https://quarto-webr.thecoatlessprofessor.com/qwebr-faq.html
- quarto-live, loading packages / exercises: https://r-wasm.github.io/quarto-live/getting_started/packages.html
