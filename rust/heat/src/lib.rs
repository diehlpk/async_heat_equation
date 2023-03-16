//  Copyright (c) 2023 AUTHORS
//
//  SPDX-License-Identifier: BSL-1.0
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

use std::sync::{Arc, Mutex};
use std::sync::mpsc::{channel, Receiver, Sender};
use std::thread::spawn;

// Heat transfer coefficient
pub const K: f64 = 0.5;

// Time step
pub const DT: f64 = 1.;

// Grid spacing
pub const DX: f64 = 1.;

fn heat(left: f64, middle: f64, right: f64) -> f64 {
    middle + (K * DT / (DX * DX)) * (left - 2. * middle + right)
}

type Tx = Sender<f64>;
type Rx = Receiver<f64>;

pub struct State {
    parts: Vec<Arc<Mutex<[Vec<f64>; 2]>>>,
    left_ghosts: Vec<(Tx, Arc<Mutex<Rx>>)>,
    right_ghosts: Vec<(Tx, Arc<Mutex<Rx>>)>,
    nx: usize,
    nt: usize,
    threads: usize
}

impl State {
    pub fn new(nx: usize, nt: usize, threads: usize) -> Self {
        let mut initial_grid: Vec<f64> = Vec::with_capacity(nx);

        { // Fill the initial grid with ascending values
            let mut i = -1_f64;
            initial_grid.resize_with(nx, || {
                i += 1_f64;
                i
            });
        }

        let chunk_size = get_chunk_size(nx, threads);

        let parts: Vec<Arc<Mutex<[Vec<f64>; 2]>>> =
            initial_grid.chunks(chunk_size)
                        .map(|c| {
                            let mut aux_part = Vec::with_capacity(c.len());
                            aux_part.resize(c.len(), 0.0);
                            Arc::from(Mutex::from([c.to_vec(), aux_part]))
                        }).collect();

        assert_eq!(parts.len(), threads, "{} != {}", parts.len(), threads);

        let left_ghosts: Vec<(Tx, Arc<Mutex<Rx>>)> =
            (0..threads).map(|_i| channel())
                        .map(|(tx, rx)| (tx, Arc::from(Mutex::from(rx))))
                        .collect();

        let right_ghosts: Vec<(Tx, Arc<Mutex<Rx>>)> =
            (0..threads).map(|_i| channel())
                        .map(|(tx, rx)| (tx, Arc::from(Mutex::from(rx))))
                        .collect();

        Self {
            parts,
            left_ghosts,
            right_ghosts,
            nx,
            nt,
            threads
        }
    }

    pub fn work(&self) {
        let mut handles = Vec::with_capacity(self.threads);

        for i in 0..self.threads {

            //region Per-thread state

            let part = Arc::clone(&self.parts[i]);

            let left_tx = self.left_ghosts[i].0.clone();
            let right_tx = self.right_ghosts[i].0.clone();

            let left_rx = if i == 0 {
                None
            } else {
                Some(Arc::clone(&self.right_ghosts[i - 1].1))
            };

            let right_rx = if i == self.threads - 1 {
                None
            } else {
                Some(Arc::clone(&self.left_ghosts[i + 1].1))
            };

            let nt = self.nt;

            //endregion Per-thread state

            handles.push(spawn(move || {
                let mut part = part.lock().unwrap();
                let len = part[0].len();

                for t in 0..nt {
                    left_tx.send(part[current_idx(t)][0]).unwrap();
                    right_tx.send(part[current_idx(t)][len - 1]).unwrap();

                    part[aux_idx(t)][0] = heat(
                        opt_recv(&left_rx),
                        part[current_idx(t)][0],
                        part[current_idx(t)][1],
                    );

                    part[aux_idx(t)][len - 1] = heat(
                        part[current_idx(t)][len - 2],
                        part[current_idx(t)][len - 1],
                        opt_recv(&right_rx),
                    );

                    for idx in 1..len - 1 {
                        part[aux_idx(t)][idx] = heat(
                            part[current_idx(t)][idx - 1],
                            part[current_idx(t)][idx],
                            part[current_idx(t)][idx + 1]
                        );
                    }
                }
            }));
        }

        for h in handles {
            h.join().unwrap();
        }
    }

    pub fn collect_space(&self) -> Vec<f64> {
        let mut v: Vec<f64> = Vec::with_capacity(self.nx);

        for part in &self.parts {
            for e in part.lock().unwrap()[self.nt % 2].iter() {
                v.push(*e);
            }
        }

        v
    }

    pub fn get_nx(&self) -> usize {
        self.nx
    }

    pub fn get_nt(&self) -> usize {
        self.nt
    }

    pub fn get_threads(&self) -> usize {
        self.threads
    }
}

fn get_chunk_size(nx: usize, threads: usize) -> usize {
    (nx as f64 / threads as f64).ceil() as usize
}

#[inline]
pub fn current_idx(t: usize) -> usize {
    t % 2
}

#[inline]
pub fn aux_idx(t: usize) -> usize {
    (t + 1) % 2
}

fn opt_recv(o: &Option<Arc<Mutex<Rx>>>) -> f64 {
    o.as_ref().map_or_else(|| Ok(0.0), |rx| rx.lock().unwrap().recv()).unwrap()
}
