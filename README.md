
<!-- README.md is generated from README.Rmd. Please edit that file -->
cSEM
====

WARNING: THIS IS WORK IN PROGRESS. BREAKING CHANGES MAY OCCUR. Do not use the package before the first stable relase (which will be 0.0.1, towards the end of 2018).

Purpose
-------

Estimate, analyse, test and study linear and nonlinear structural equation models using composite based approaches, procedures and tests including e.g. PLS, GSCA, 2SLS estimation and numerous tests.

Installation
------------

``` r
# Currently only a development version from GitHub is available:
# install.packages("devtools")
devtools::install_github("M-E-Steiner/cSEM")
```

Philopsophy/Goals/Ideas
-----------------------

-   Easy to use by non-R experts:
    -   Functions `csem` and `cca` provide default choices for most of its arguments (similarity to the `sem` and `cfa` functions of the [lavaan](http://lavaan.ugent.be/) package is intended).
    -   Well documented (Vignettes, HTML output, a website, intro course(s)). Of course this may take some time!
    -   There will be an extensive (non-expert) visually and didactically appealing documentation designed to make the learning curve of both the methods involved and the package as flat as possible.
    -   Structured output/results that aims to be "easy"" in a sense that it is
        -   ... descriptive/verbose
        -   ... easy to export to other environments such as MS Word, Latex files etc. (exportability)
        -   ... easy to migrate from/to/between other PLS/VB/CB-based systems (lavaan, semPLS, ADANCO, SmartPLS) (this will also take a lot of time!)
    -   (In the future) Intro courses, accompaning website, cheatsheets.
-   The package is designed to be flexible/modular enough so that researchers developing new methods can take specific function provided by the package and alter them according to their need without working their way through a chain of other functions (naturally this will not always be possible).
-   Modern in a sense that the package integrates modern developments within the R community. This mainly includes ideas/recommendations/design choices that fead into the packages of the [tidyverse](https://github.com/tidyverse/tidyverse).

To do
-----

### Before the initial relase

-   Implement:
    -   Fixed weights
    -   Unit weights
    -   All of Kettenring's (1971) criteria for obtaining weights
        -   SUMCOR
        -   MAXVAR
        -   SSQCOR
        -   MINVAR
        -   GENVAR
    -   GSCA <https://cran.r-project.org/web/packages/gesca/gesca.pdf>
    -   2SLS for linear models but possibly also for non-linear models
-   Tests
    -   Test for overall model fit (Dijkstra & Henseler)
    -   (bootstrapped) Hausman test (for linear (and non-linear?) models)
-   Compute direct, indirect and total effect.
-   Allow for bootstrapping (use the `boot` package)/ jackknife?
    -   A bootstrap function should accept a user defined function that can be bootstraped with it.
-   Allow for different convergence criteria in PLS (as in [matrixpls](https://github.com/mronkko/matrixpls))
-   Automatically distinguish between linear and nonlinear models (will be useful for performance reasons).
-   Use the [crayon package](https://github.com/r-lib/crayon) and the [cli package](https://github.com/r-lib/cli) to produce good-looking/colorful console output.
-   Use the [spelling package](https://github.com/ropensci/spelling) to do spellchecking of the package documentation (just before the release).
-   Move the `.PLS_weight_scheme_inner` argument to the `...` arguement list.

### At some point ...

-   Vignettes for all important aspects of the package and the methods used.
-   GSCAm
-   Enable cross-PLS-platform use by writting functions that make it easy to export and import models/results from/to.
-   Factor score path analysis von Ives Rosseel
-   Compute effect size, Cohens f2 (Cohen, 1988)
