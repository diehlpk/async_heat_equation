## Implementation in rust

### Interesting features



### Neutral features

* Installation on Fedora 35 is rather big with `Installed size: 1.4 G` for some programming language. Therefore, swift is excluded from [circle-ci](https://app.circleci.com/pipelines/github/diehlpk/monte-carlo-codes?branch=main) continuous testing to not blow up the [Docker image](https://hub.docker.com/r/diehlpk/monte-carlo-codes). 


### Surprising features

* It seems rust comes with minimal functionality and most features need to be installed. For example, [random numbers](https://rust-lang-nursery.github.io/rust-cookbook/algorithms/randomness.html) are not available and an external library is needs to be compiled. [Cargo](https://doc.rust-lang.org/cargo/index.html) is the package manager for Rust which downloads and compiles the dependencies. Each [Crate](https://doc.rust-lang.org/cargo/appendix/glossary.html#crate)  has a `Cargo.toml` file to define all the dependencies. 
