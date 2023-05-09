//  Copyright (c) 2023 AUTHORS
//
//  SPDX-License-Identifier: BSL-1.0
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

use std::env;
use std::time::Instant;
use heat_ghosts_mini::{DT, DX, State};

fn main() {
    let args: Vec<String> = env::args().collect();

    let threads = args[1].parse::<usize>().unwrap();
    let nt = args[2].parse::<usize>().unwrap();
    let nx = args[3].parse::<usize>().unwrap();

    let mut s = State::new(nx, nt, threads);
    let t = Instant::now();

    s.work();

    let elapsed = t.elapsed();

    println!("rust,{0},{1},{2},{3},{4},{5}", s.nx, s.nt, s.threads, DT, DX, elapsed.as_secs_f64());

    if nx <= 20 {
        println!("Final grid (NX = {0}): {1:?}", nx, s.collect_space());
    }
}
