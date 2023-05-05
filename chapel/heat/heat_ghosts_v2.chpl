//  Copyright (c) 2023 AUTHORS
//
//  SPDX-License-Identifier: BSL-1.0
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//using Distributed

// Notes on running:
// (1) Use CHPL_RT_NUM_THREADS_PER_LOCALE to set the desired parallelism.
// (2) This program does not support positional args.
// (3) Use --nx=YYY to set the number of cells to YYY.
// (4) use --nt=YYY to set the number of time steps to YYY.
// (5) Use --nthreads=Z to set the number of tasks to Z. Defaults to the number of available cores.
// CHPL_RT_NUM_THREADS_PER_LOCALE=6 ./heat --nx=10_000_000 [--nthreads=6]

use Time;

config const k = 0.4,
             dt = 1.0,
             dx = 1.0;

config const nx = 1_000_000,
             nt = 100,
             nthreads = here.maxTaskPar;

config const verbose = false;

const alp = k*dt/(dx*dx),
      tx = (2+nx)/nthreads;

var data: [0..<nx] real;

var ghosts: [0..1, 0..<nthreads] sync real;
param LEFT = 0, RIGHT = 1;

proc main() {
  var t = new stopwatch();

  t.start();
  coforall tid in 0..<nthreads do work(tid);
  t.stop();

  if verbose then writeln(data);
  writeln("chapel,",nx,",",nt,",",here.maxTaskPar,",",dt,",",dx,",",t.elapsed(),",0");
}

proc work(tid: int) {
  const lo: int = tx*tid - 1,
        hi: int = min(tx*(tid+1),nx) + 1;

  const taskDom = {lo..<hi},
        taskDomInner = taskDom.expand(-1);

  var data1, data2: [taskDom] real;
  forall i in taskDom do data1[i] = i + 1;

  const tidP1 = (tid + 1) % nthreads,
        tidM1 = (tid + nthreads - 1) % nthreads;

  ghosts[RIGHT, tidM1].writeEF(data1[taskDomInner.low]);
  ghosts[LEFT, tidP1].writeEF(data1[taskDomInner.high]);

  for 1..nt {
    data1[taskDom.low] = ghosts[LEFT, tid].readFE();
    data1[taskDom.high] = ghosts[RIGHT, tid].readFE();

    foreach i in taskDomInner do
      data2[i] = data1[i] + alp*(data1[i+1] + data1[i-1] - 2*data1[i]);

    ghosts[RIGHT, tidM1].writeEF(data1[taskDomInner.low]);
    ghosts[LEFT, tidP1].writeEF(data1[taskDomInner.high]);

    data1 <=> data2;
  }

  data[taskDomInner] = data1[taskDomInner];
}
