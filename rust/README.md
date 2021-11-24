## Implementation in rust

### Interesting features

* Error messages are 

* Debugging is really convinient, since again the error messages are clear 
  ```bash
  thread 'main' panicked at 'called `Result::unwrap()` on an `Err` value: ParseIntError { kind: PosOverflow }', src/main.rs:34:39
  note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
  ```
  and by exporting `export RUST_BACKTRACE=1` more details of the back trace are printed
  ```bash
  thread 'main' panicked at 'called `Result::unwrap()` on an `Err` value: ParseIntError { kind: PosOverflow }', src/main.rs:34:39
stack backtrace:
   0: rust_begin_unwind
   1: core::panicking::panic_fmt
   2: core::result::unwrap_failed
   3: core::result::Result<T,E>::unwrap
             at /builddir/build/BUILD/rustc-1.56.1-src/library/core/src/result.rs:1299:23
   4: rust::main
             at ./src/main.rs:34:17
   5: core::ops::function::FnOnce::call_once
   ``` 
   This seems to be interesting, since the debugger is included and no external tool as the gdb is needed.


### Neutral features

* There is no global package installation, like [pip](https://pypi.org/project/pip/) for Python. This is the same as for the C++ language, however, Cargo installs all dependencies for each Crate which is comparable to the [virtualenv](https://docs.python.org/3/library/venv.html) in python to avoid global installs and have different versions for each environment. 

### Surprising features

* It seems rust comes with minimal functionality and most features need to be installed. For example, [random numbers](https://rust-lang-nursery.github.io/rust-cookbook/algorithms/randomness.html) are not available and an external library is needs to be compiled. [Cargo[(https://doc.rust-lang.org/cargo/index.html) is the package manager for Rust which downloads and compiles the dependencies. Each [Crate](https://doc.rust-lang.org/cargo/appendix/glossary.html#crate)  has a `Cargo.toml` file to define all the dependencies. 
