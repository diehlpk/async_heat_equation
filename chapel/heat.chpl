//  Copyright (c) 2023 AUTHORS
//
//  SPDX-License-Identifier: BSL-1.0
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//
// Notes on running:
// (1) Use CHPL_RT_NUM_THREADS_PER_LOCALE to set the desired parallelism.
// (2) This program does not support positional args.
// (3) Use --nx=YYY to set the number of cells to YYY.
// (4) use --nt=YYY to set the number of time steps to YYY.
// CHPL_RT_NUM_THREADS_PER_LOCALE=6 ./heat --nx=10_000_000

use IO;
use Time;
use FileSystem;
use Reflection;

config const tasks: int = 1;
config const ghosts: int = 1;
config const k: real = 0.4;
config const dt: real = 1.0;
config const dx: real = 1.0;

config const nx: int = 1_000_000;
config const nt: int = 100;
config const threads: int = 1;

const NX : int = nx + 1;

var data: [0..NX] real;
var data2: [0..NX] real;

proc update(d : []real, d2 : []real) {
  forall i in 1..NX-1 do {
    d2[i] = d[i] + dt*k/(dx*dx)*(d[i+1] + d[i-1] - 2*d[i]);
  }
  d2[0] = d2[NX-1];
  d2[NX] = d2[1];
}

proc main() {
  forall i in 0..NX do {
    data[i] = 1 + (i-1 + nx) % nx;
    data2[i] = 0;
  }
  var t: stopwatch;
  t.start();
  for t in 0..nt do {
    if t % 2 == 0 {
      update(data, data2);
    } else {
      update(data2, data);
    }
  }
  t.stop();
  if data2.size < 20 {
    writeln(data2);
  }
  writeln("time: ",t.elapsed());
  /* // Can't figure out how to append
  var fn = "perfdata.csv";
  if !exists(fn) {
    var output = open(fn, ioMode.cw);
    var wri = output.writer();
    wri.writeln("lang,nx,nt,threads,dt,dx,total time,flops");
    wri.close();
    output.close();
  }
  var output = open(fn, ioMode.a); // this doesn't work
  var wri = output.writer();
  wri.writeln("chapel,",nx,",",nt,",",here.numPUs(),",",dt,",",dx,",",t.elapsed(),",0");
  wri.close();
  output.close();
  */
  writeln("chapel,",nx,",",nt,",",here.numPUs(),",",dt,",",dx,",",t.elapsed(),",0");
}
