//  Copyright (c) 2023 AUTHORS
//
//  SPDX-License-Identifier: BSL-1.0
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

#![feature(portable_simd)]

use std::mem;
use std::simd::f64x8;
use std::sync::{Arc, Mutex};
use std::sync::mpsc::{channel, Receiver, Sender};
use std::thread::spawn;

// Heat transfer coefficient
pub const K: f64 = 0.5;

// Time step
pub const DT: f64 = 1.;

// Grid spacing
pub const DX: f64 = 1.;

const CONSTANT_HEAT_TERM: f64 = K * DT / (DX * DX);

fn heat_scalar(left: f64, middle: f64, right: f64) -> f64 {
    middle + CONSTANT_HEAT_TERM * (left - 2. * middle + right)
}

#[inline]
fn heat_simd(left: &[f64], middle: &[f64], right: &[f64], result: &mut [f64]) {
    assert_eq!(middle.len(), left.len());
    assert_eq!(middle.len(), right.len());
    assert_eq!(middle.len(), result.len());

    let constant_term_vector = f64x8::splat(CONSTANT_HEAT_TERM);
    let two_vector = f64x8::splat(2.0);

    let len = middle.len();
    let simd_len = len / 8;

    // Process elements in sets of 8 with SIMD
    for i in 0..simd_len {
        let left_vector = f64x8::from_slice(&left[i*8..]);
        let middle_vector = f64x8::from_slice(&middle[i*8..]);
        let right_vector = f64x8::from_slice(&right[i*8..]);

        let result_simd = middle_vector + constant_term_vector * (left_vector - two_vector * middle_vector + right_vector);

        let result_slice = &mut result[i*8..(i+1)*8];
        result_slice.copy_from_slice(result_simd.as_array());
    }

    // Process the rest (n < 8) normally
    for i in (simd_len * 8)..len {
        result[i] = heat_scalar(left[i], middle[i], right[i]);
    }
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
                Arc::clone(&self.right_ghosts[self.threads - 1].1)
            } else {
                Arc::clone(&self.right_ghosts[i - 1].1)
            };

            let right_rx = if i == self.threads - 1 {
                Arc::clone(&self.left_ghosts[0].1)
            } else {
                Arc::clone(&self.left_ghosts[i + 1].1)
            };

            let nt = self.nt;

            //endregion Per-thread state

            handles.push(spawn(move || {
                let mut part = part.lock().unwrap();
                let len = part[0].len();
                let left_rx = left_rx.lock().unwrap();
                let right_rx = right_rx.lock().unwrap();

                let (current, aux) = part.split_at_mut(1);

                let mut current = &mut current[0];
                let mut aux = &mut aux[0];

                for _t in 0..nt {
                    left_tx.send(aux[0]).unwrap();
                    right_tx.send(current[len - 1]).unwrap();

                    aux[0] = heat_scalar(
                        left_rx.recv().unwrap(),
                        current[0],
                        current[1],
                    );

                    aux[len - 1] = heat_scalar(
                        current[len - 2],
                        current[len - 1],
                        right_rx.recv().unwrap(),
                    );

                    heat_simd(
                        &current[0..len - 2],
                        &current[1..len - 1],
                        &current[2..len],
                        &mut aux[1..len - 1]
                    );

                    mem::swap(&mut current, &mut aux);
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
