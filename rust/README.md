## Implementation in rust

### Interesting features

  * Error messages are 

### Neutral features

  * There is no global package installation, like [pip](https://pypi.org/project/pip/) for Python. This is the same as for the C++ language, however, Cargo installs all dependencies for each Crate wwhich is comaprable to the [virtualenv](https://docs.python.org/3/library/venv.html) in python to avoid global installs and have different versions for each environment. 

### Suprising features

  * It seems rust comes with minimal functionality and most features need to be installed. For exmaple, [random numbers](https://rust-lang-nursery.github.io/rust-cookbook/algorithms/randomness.html) are not available and an external library is needs to be compiled. [Cargo[(https://doc.rust-lang.org/cargo/index.html) is the package manager for Rust whch downloads and compiles the depdencies. Each [Crate](https://doc.rust-lang.org/cargo/appendix/glossary.html#crate)  has a `Cargo.toml` file to define all the dependencies. 
