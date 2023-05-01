//  Copyright (c) 2023 AUTHORS
//
//  SPDX-License-Identifier: BSL-1.0
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//using Distributed

use Time;

config const check_correctness : bool = false;

extern proc getenv(name : c_string) : c_string;

config const ghosts: int = 1;
config const k: real = 0.4;
config const dt: real = 1.0;
config const dx: real = 1.0;

config const nx: int = 1_000_000;
config const nt: int = 100;
config const nthreads: int = 1;

const alp : real = k*dt/(dx*dx);

const tx : int = (2*ghosts+nx)/nthreads;

//---- Start implement the queues---
const qsize : int = 12;

var qarray : [0..2*qsize*nthreads] real;
var qhead : [0..2*nthreads] int;
var qtail : [0..2*nthreads] int;

var data : [0..nx-1] real;

const leftq = 1;
const rightq = 0;

proc push_queue(left_right : int, threadno : int, val : real) {
    const qno : int = left_right + 2 * threadno;
    const t : int = qtail[qno];
    const idx : int = qno * qsize + t % qsize + 1;
    qarray[idx] = val;
    qtail[qno] += 1;
}

proc pop_queue(left_right : int, threadno : int ) {
    const qno = left_right + 2 * threadno;
    const h = qhead[qno];
    const idx = qno * qsize + h % qsize + 1;
    var t = qtail[qno];
    while h == t {
        sleep(0);
        t = qtail[qno];
    }
    const val = qarray[idx];
    qhead[qno] += 1;
    return val;
}

//---- End implement the queues---"

proc work(num:int) {
    //print("Start work: ",num,"\n")
    var lo : int = tx*num;
    var hi : int = tx*(num+1);
    if hi > nx {
        hi = nx;
    }
    lo -= ghosts;
    hi += ghosts;
    const sz = hi - lo;
    var data1 : [0..sz-1] real;
    var data2 : [0..sz-1] real;
    const off = 1;
    const ip1 = (num + 1) % nthreads;
    const im1 = (num + nthreads - 1) % nthreads;

    for i in 0..sz-1 {
        data1[i] = i + lo + off;
    }

    // send
    push_queue(rightq, im1, data1[1]);
    push_queue(leftq, ip1, data1[sz-2]);
    //print("Pre loop: ",num,"\n")
    for nt in 1..nt {
        //print("nt: ",nt," ",data1,"\n")
        data1[0] = pop_queue(leftq, num);
        data1[sz-1] = pop_queue(rightq, num);

        //print("Update: nt: ",nt," num: ",num,"\n")
        for i in 1..sz-2 {
            //print("Data i: ",i,"\n")
            data2[i] = data1[i] + alp*(data1[i+1] + data1[i-1] - 2*data1[i]);
        }
        //print("Post Update: nt: ",nt," num: ",num,"\n")
        push_queue(rightq, im1, data1[1]);
        push_queue(leftq, ip1, data1[sz-2]);
        // swap
        data1 <=> data2;
    }
    //print("End Evo\n")
    data1[0] = pop_queue(leftq, num);
    data1[sz-1] = pop_queue(rightq, num);
    for i in 0..sz-1 {
      var j = i + lo;
      if j >= 0 && j < nx {
        data[j] = data1[i];
      }
    }
}

proc main() {
  var t: stopwatch;
  t.start();
  forall tno in 0..nthreads - 1 do {
    work(tno);
  }
  t.stop();
  if(nx <= 20) {
    writeln(data);
  }
  writeln("chapel,",nx,",",nt,",",getenv('CHPL_RT_NUM_THREADS_PER_LOCALE'.c_str()):string,",",dt,",",dx,",",t.elapsed(),",0");
}
