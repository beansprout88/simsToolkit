
# simsToolkit

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/simsToolkit)](https://CRAN.R-project.org/package=simsToolkit)
[![R-CMD-check](https://github.com/beansprout88/simsToolkit/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/beansprout88/simsToolkit/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/beansprout88/simsToolkit/branch/master/graph/badge.svg)](https://app.codecov.io/gh/beansprout88/simsToolkit?branch=master)
<!-- badges: end -->

Toolkit for analysis of ToF-SIMS mass spectrometry images

Install with `devtools::install_github("danielgreenwood/simsToolkit")`

simsToolkit contains the functions used for the analysis of
Time-of-Flight Secondary Ion Mass Spectrometry (ToF-SIMS) images in the
following PhD thesis:

Greenwood, Daniel Joseph; (2019) Visualising the subcellular
distribution of antibiotics against tuberculosis. Doctoral thesis
(Ph.D), UCL (University College London)
<https://discovery.ucl.ac.uk/id/eprint/10086492/>

![image](https://github.com/danielgreenwood/simsToolkit/assets/117200027/4c5f211b-4f26-4105-b39d-c7a1379b53fb)

Images and spectra were firstly analysed in SurfaceLab 6.3 (ION-TOF,
Germany). Spectra were segmented using the automated peak detection
algorithm, and voxel-by-voxel data exported into a .txt file.

Functions are provided for the following activities:

- extraction of data from .txt

- poisson-scaled principal component analysis

- z-correction

- 3D visualization
