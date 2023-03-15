//  Copyright (c) 2023 AUTHORS
//
//  SPDX-License-Identifier: BSL-1.0
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

use std::{env, fs};
use std::error::Error;
use std::fs::OpenOptions;
use std::path::Path;
use std::str::FromStr;
use std::time::{Duration, Instant};
use std::io::Write;
use heat::{DT, DX, State};

fn main() {
    let args: Vec<String> = env::args().collect();

    let threads = get_arg(&args, 1, "threads");
    let nt = get_arg(&args, 2, "nt");
    let nx = get_arg(&args, 3, "nx");

    let s = State::new(nx, nt, threads);
    let t = Instant::now();

    s.work();

    let elapsed = t.elapsed();

    println!("Elapsed: {}ms", elapsed.as_millis());
    log_csv(&s, elapsed).expect("Couldn't write perfdata.csv");
}

fn get_arg<F: FromStr>(args: &[String], idx: usize, purpose: &str) -> F
where <F as FromStr>::Err: Error {
    args.get(idx)
        .unwrap_or_else(|| panic!("Arg {idx} ({purpose}) missing"))
        .parse::<F>()
        .unwrap_or_else(|e| panic!("Arg {idx} ({purpose}) not convertible: {e:?}"))
}

fn log_csv(s: &State, elapsed: Duration) -> Result<(), Box<dyn Error>> {
    let file_name = Path::new("perfdata.csv");

    if !file_name.exists() {
        fs::write(file_name, "lang,nx,nt,threads,dt,dx,seconds\n")?;
    }

    let mut file = OpenOptions::new().append(true).open(file_name)?;

    writeln!(&mut file, "rust,{0},{1},{2},{3},{4},{5}", s.get_nx(), s.get_nt(), s.get_threads(), DT, DX, elapsed.as_secs_f64())?;

    Ok(())
}
