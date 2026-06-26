# Exploratory Spatial Data Analysis (ESDA): a focused review

Scope: the foundations of ESDA for a Session-II lecture. What ESDA is, why spatial data
needs its own exploratory approach, where it came from, and its core methods. Local
indicators (LISA, Getis-Ord) and the full clustering machinery are deferred to a later
session and are only named here as the next step.

## 1. What ESDA is

Exploratory Spatial Data Analysis is the spatial extension of Tukey's exploratory data
analysis. It is a set of techniques to describe and visualise spatial distributions, identify
atypical locations (spatial outliers), discover patterns of spatial association, and suggest
spatial regimes or other forms of spatial heterogeneity (Anselin 1999). In short, it
spatialises EDA and adds an explicit concern with location, neighbourhood, and spatial
pattern.

ESDA is hypothesis-generating, not hypothesis-testing. It helps an analyst sift through
spatial data, notice unusual patterns, and form questions that confirmatory spatial models
can then test. This exploratory stance, "favouring an approach that generally eschews
hypothesis testing", is inherited directly from Tukey (1977).

## 2. Why spatial data needs its own EDA

Standard EDA assumes observations are independent. Spatial data usually are not. Two
properties make spatial data "special" (Anselin 1989) and motivate ESDA:

- **Spatial dependence (autocorrelation).** Near things are more related than distant things
  (Tobler's First Law, 1970). Values at nearby locations tend to resemble one another, which
  violates independence and is itself often the pattern of interest.
- **Spatial heterogeneity.** Relationships and distributions are not constant across space;
  means, variances, and processes can differ by region.

Two practical consequences also belong in an ESDA lecture: the **modifiable areal unit
problem** (results depend on how areas are bounded and aggregated) and the **ecological
fallacy** (area-level patterns need not hold for individuals). ESDA tools are designed to
surface these spatial features rather than treat them as nuisance.

## 3. Exploratory vs confirmatory

ESDA sits at the front of the spatial analysis workflow. It is descriptive and visual, used
to generate hypotheses about where and how values cluster or differ, before any model is
fitted. Confirmatory spatial analysis (spatial regression, spatial econometrics) comes later
and tests those hypotheses (Anselin 1988; Haining 2003). Keeping the two separate is a core
teaching point.

## 4. Historical roots

- **Tukey (1977)** established exploratory data analysis as a discipline of visual,
  resistant, hypothesis-free data description.
- **Openshaw, Charlton, Wymer & Craft (1987)** built the Geographical Analysis Machine, an
  early automated search for clustering in point data.
- **Interactive and dynamic graphics** for spatial data followed: REGARD (Unwin, Wills &
  Haslett, 1990), MANET, and the linking of statistical graphics to maps. Bailey & Gatrell
  (1995) and Anselin (1999) consolidated these into "interactive spatial data analysis".
- **Software** made ESDA routine: SpaceStat, then GeoDa (Anselin, Syabri & Kho 2006), and in
  R the `spdep` lineage (Bivand and colleagues).

## 5. Core ESDA methods (foundational level)

At the introductory level ESDA is mostly about looking carefully, in three linked ways:

1. **Mapping spatial distributions.** Thematic and choropleth maps, with attention to
   classification, rates vs counts, and the visual encoding of a variable. The map is the
   primary ESDA instrument.
2. **Linked and dynamic graphics.** Histograms, box plots, scatter plots, and parallel
   coordinate plots brushed and linked to the map, so a selection in one view highlights the
   same observations in the others. This is the interactive tradition (Anselin 1999; GeoDa).
3. **Finding atypical locations.** Spatial outliers, that is, locations whose value is unlike
   their neighbours, and a first sense of whether high or low values cluster.

These lead into the idea of a **spatial weights matrix** (which locations are neighbours, and
how strongly) and a single **global** measure of spatial autocorrelation such as Moran's I,
which answers "is there overall spatial pattern, yes or no". That is the natural stopping
point for an introductory ESDA session.

## 6. ESDA in public health and epidemiology

ESDA is well established in spatial epidemiology. It is used to map disease rates, identify
candidate hot spots and unusual areas, and generate hypotheses about environmental or social
drivers before formal modelling (Delmelle & Kanaroglou 2013). Reviews note that exploratory
methods, including kernel density estimation and cluster detection, are central to
epidemiological surveillance and to deciding which areas may be at risk. Applications span
infectious and chronic disease and increasingly extend to space-time (exploratory
spatio-temporal data analysis, for example dengue in Punjab, India). For an Indian public
health audience this connects naturally to district and facility level indicators (NFHS,
notification data) where ESDA precedes any clustering or regression.

## 7. Tools

- **GeoDa** (point-and-click, teaching-friendly; Anselin et al. 2006).
- **R**: `sf` for spatial data, `spdep` and `geostan` for weights and autocorrelation,
  `tmap` and `ggplot2`/`geom_sf` for thematic maps, `mapview`/`leaflet` for interactive
  exploration.

## 8. What comes next (deferred)

The next step beyond this review is the move from a single global statistic to **local
indicators of spatial association (LISA)** and hot-spot statistics (local Moran's I,
Getis-Ord), which locate clusters and classify them (Anselin 1995). That material belongs in
the later analysis-and-clustering session and is intentionally left out here.

## Key references

- Tukey, J.W. (1977). *Exploratory Data Analysis*. Addison-Wesley.
- Tobler, W. (1970). A computer movie simulating urban growth in the Detroit region.
  *Economic Geography* 46: 234-240.
- Openshaw, S., Charlton, M., Wymer, C. & Craft, A. (1987). A Mark 1 Geographical Analysis
  Machine. *Int. J. GIS* 1: 335-358.
- Anselin, L. (1988). *Spatial Econometrics: Methods and Models*. Kluwer.
- Anselin, L. (1989). *What is Special About Spatial Data?* NCGIA Technical Report 89-4.
- Anselin, L. (1999). Interactive techniques and exploratory spatial data analysis. In
  *Geographical Information Systems* (Longley et al., eds).
- Bailey, T.C. & Gatrell, A.C. (1995). *Interactive Spatial Data Analysis*. Longman.
- Haining, R. (2003). *Spatial Data Analysis: Theory and Practice*. Cambridge Univ. Press.
- Anselin, L., Syabri, I. & Kho, Y. (2006). GeoDa: an introduction to spatial data analysis.
  *Geographical Analysis* 38: 5-22.
- Delmelle, E. & Kanaroglou, P. (2013). *Spatial Analysis and Health* (introduction chapter).
- Anselin, L. (1995). Local indicators of spatial association (LISA). *Geographical Analysis*
  27: 93-115. [deferred topic]

## Sources consulted (web)

- Anselin, *Interactive Techniques and ESDA*: https://researchrepository.wvu.edu/rri_pubs/200/
- ESDA overview (ScienceDirect Topics): https://www.sciencedirect.com/topics/earth-and-planetary-sciences/exploratory-spatial-data-analysis
- Spatial Analysis and Health, intro chapter (Delmelle & Kanaroglou): https://pages.charlotte.edu/wp-content/uploads/sites/150/2012/12/IntroductionSpatialAnalysisAndHealthDelmelleKanaroglou.pdf
- ESDA for health/environment disparities (PMC): https://pmc.ncbi.nlm.nih.gov/articles/PMC4650891/
- Paradigm shift of spatial epidemiology (Frontiers/PMC 2025): https://pmc.ncbi.nlm.nih.gov/articles/PMC12558956/
- ESTDA of dengue, Punjab India (ScienceDirect): https://www.sciencedirect.com/science/article/abs/pii/S1574954123000493
- geostan, measuring spatial autocorrelation (CRAN vignette): https://cran.r-project.org/web/packages/geostan/vignettes/measuring-sa.html
