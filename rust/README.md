## Implementation in rust

### Interesting features

  * Error messages are 

### Neutral features

  * There is no global package installation, like [pip](https://pypi.org/project/pip/) for Python. This is the same as for the C++ language, however, Cargo installs all dependencies for each Crate which is comparable to the [virtualenv](https://docs.python.org/3/library/venv.html) in python to avoid global installs and have different versions for each environment. 

### Surprising features

  * It seems rust comes with minimal functionality and most features need to be installed. For example, [random numbers](https://rust-lang-nursery.github.io/rust-cookbook/algorithms/randomness.html) are not available and an external library is needs to be compiled. [Cargo[(https://doc.rust-lang.org/cargo/index.html) is the package manager for Rust which downloads and compiles the dependencies. Each [Crate](https://doc.rust-lang.org/cargo/appendix/glossary.html#crate)  has a `Cargo.toml` file to define all the dependencies. 
