
# simsToolkit

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/simsToolkit)](https://CRAN.R-project.org/package=simsToolkit)

<!-- badges: end -->

Toolkit for analysis of ToF-SIMS mass spectrometry images

simsToolkit contains the functions used for the analysis of
Time-of-Flight Secondary Ion Mass Spectrometry (ToF-SIMS) images in the
following PhD thesis:

Greenwood, Daniel Joseph; (2019) Visualising the subcellular
distribution of antibiotics against tuberculosis. Doctoral thesis
(Ph.D), UCL (University College London)
<https://discovery.ucl.ac.uk/id/eprint/10086492/>

Images and spectra were firstly analysed in SurfaceLab 6.3 (ION-TOF,
Germany). Spectra were segmented using the automated peak detection
algorithm, and voxel-by-voxel data exported into a .txt file.

Functions are provided for the following activities:

- extraction of data from .txt

- poisson-scaled principal component analysis

- z-correction

- 3D visualization
