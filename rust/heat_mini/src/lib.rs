//  Copyright (c) 2023 AUTHORS
//
//  SPDX-License-Identifier: BSL-1.0
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

use std::{mem, thread};
use std::sync::mpsc::{channel, Receiver, Sender};

// Heat transfer coefficient
pub const K: f64 = 0.4;

// Time step
pub const DT: f64 = 1.;

// Grid spacing
pub const DX: f64 = 1.;

const CONSTANT_HEAT_TERM: f64 = K * DT / (DX * DX);

fn heat(left: f64, middle: f64, right: f64) -> f64 {
    middle + CONSTANT_HEAT_TERM * (left - 2. * middle + right)
}

struct ThreadPart {
    space_a: Vec<f64>,
    space_b: Vec<f64>,
    left_tx: Sender<f64>,
    right_tx: Sender<f64>,
    left_rx: Receiver<f64>,
    right_rx: Receiver<f64>
}

pub struct State {
    parts: Vec<ThreadPart>,
    pub nx: usize,
    pub nt: usize,
    pub threads: usize
}

impl State {
    pub fn new(nx: usize, nt: usize, threads: usize) -> Self {
        let mut initial_grid: Vec<f64> = Vec::with_capacity(nx);

        let mut i = -1_f64;
        initial_grid.resize_with(nx, || {
            i += 1_f64;
            i
        });

        let chunk_size = (nx as f64 / threads as f64).ceil() as usize;

        let mut left_ghosts = make_ghost_channels(threads);
        let mut right_ghosts = make_ghost_channels(threads);

        let parts: Vec<ThreadPart> =
            initial_grid
                .chunks(chunk_size)
                .enumerate()
                .map(|(thread_num, chunk)| {
                    let mut aux_part = Vec::with_capacity(chunk.len());
                    aux_part.resize(chunk.len(), 0.0);

                    let left_rx = if thread_num == 0 {
                        right_ghosts[threads - 1].1.take()
                    } else {
                        right_ghosts[thread_num - 1].1.take()
                    }.unwrap();

                    let right_rx = if thread_num == threads - 1 {
                        left_ghosts[0].1.take()
                    } else {
                        left_ghosts[thread_num + 1].1.take()
                    }.unwrap();

                    ThreadPart {
                        space_a: chunk.to_vec(),
                        space_b: aux_part,
                        left_tx: left_ghosts[thread_num].0.take().unwrap(),
                        right_tx: right_ghosts[thread_num].0.take().unwrap(),
                        left_rx,
                        right_rx,
                    }
                }).collect();

        Self {
            parts,
            nx,
            nt,
            threads
        }
    }

    pub fn work(&mut self) {
        thread::scope(|scope| {
            for thread_part in self.parts.iter_mut() {
                let nt = self.nt;

                scope.spawn(move || {
                    let chunk_len = thread_part.space_a.len();

                    let mut current = &mut thread_part.space_a;
                    let mut aux = &mut thread_part.space_b;

                    for _t in 0..nt {
                        thread_part.left_tx.send(current[0]).unwrap();
                        thread_part.right_tx.send(current[chunk_len - 1]).unwrap();

                        aux[0] = heat(
                            thread_part.left_rx.recv().unwrap(),
                            current[0],
                            current[1],
                        );

                        aux[chunk_len - 1] = heat(
                            current[chunk_len - 2],
                            current[chunk_len - 1],
                            thread_part.right_rx.recv().unwrap(),
                        );

                        for idx in 1..chunk_len - 1 {
                            aux[idx] = heat(
                                current[idx - 1],
                                current[idx],
                                current[idx + 1]
                            );
                        }

                        mem::swap(&mut current, &mut aux);
                    }
                });
            }
        });
    }

    pub fn collect_space(&self) -> Vec<f64> {
        let mut v: Vec<f64> = Vec::with_capacity(self.nx);

        for part in &self.parts {
            for e in (if self.nt % 2 == 0 { &part.space_a } else { &part.space_b} ).iter() {
                v.push(*e);
            }
        }

        v
    }
}

fn make_ghost_channels(threads: usize) -> Vec<(Option<Sender<f64>>, Option<Receiver<f64>>)> {
    (0..threads)
        .map(|_i| channel())
        .map(|(tx, rx)| (Some(tx), Some(rx)))
        .collect()
}
