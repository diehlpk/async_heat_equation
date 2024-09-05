## Benchmarking the Parallel 1D Heat Equation Solver in Chapel, Charm++, C++, HPX, Go, Julia, Python, Rust, Swift, and Java 

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/b3f6fa94ac1144d6a9468da4e55b111d)](https://www.codacy.com/gh/diehlpk/async_heat_equation/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=diehlpk/async_heat_equation&amp;utm_campaign=Badge_Grade) [![link](https://circleci.com/gh/diehlpk/async_heat_equation/tree/main.svg?style=shield)](https://circleci.com/gh/diehlpk/async_heat_equation/tree/main) [![DOI](https://zenodo.org/badge/429990324.svg)](https://zenodo.org/badge/latestdoi/429990324)



This repo is for some small project, to compare [Rust](https://www.rust-lang.org/), [Julia](https://julialang.org/), [Swift](https://developer.apple.com/swift/), [HPX](https://github.com/STEllAR-GROUP/hpx), [Charm++](http://charmplusplus.org/), [Chapel](https://chapel-lang.org/), and [go](https://go.dev/). Recently, I got interested in these languages, 
since I read a lot about them. I mostly use C++ and Python for my research. In this repo, we will implement some 
small code to estimate Pi using the Monte Carlo method.

Next, we implement a solver for the one-dimensional heat eqaution using tasks and asynchronous programming. 

### References

* Diehl, P., Morris, M., Brandt, S.R., Gupta, N., Kaiser, H. (2024). Benchmarking the Parallel 1D Heat Equation Solver in Chapel, Charm++, C++, HPX, Go, Julia, Python, Rust, Swift, and Java. In: Zeinalipour, D., et al. Euro-Par 2023: Parallel Processing Workshops. Euro-Par 2023. Lecture Notes in Computer Science, vol 14352. Springer, Cham. [10.1007/978-3-031-48803-0_11](https://doi.org/10.1007/978-3-031-48803-0_11), [Preprint](https://arxiv.org/abs/2307.01117)
