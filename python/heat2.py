#  Copyright (c) 2023 AUTHORS
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. (See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
from typing import Optional, Tuple
from threading import Thread
from queue import Queue
import numpy as np
import sys
import time
import os
use_hw_counters : bool = sys.argv[4] == "1"

if use_hw_counters:
    from pypapi import events, papi_high as high

nx = int(sys.argv[3])        # number of nodes
k = 0.5                      # heat transfer coefficient
dt = 1.                      # time step
dx = 1.                      # grid spacing
nt = int(sys.argv[2])        # number of time steps
threads = int(sys.argv[1])   # numnber of threads

tx = nx//threads
assert tx > 0

class Worker(Thread):
    def __init__(self,num:int)->None:
        Thread.__init__(self)
        self.num : int = num
        self.lo : int = tx*num
        self.hi : int = tx*(num+1)
        self.right : Queue[float] = Queue()
        self.left : Queue[float] = Queue()
        self.sz = self.hi - self.lo
        assert self.sz > 0
        self.data = np.linspace(self.lo, self.hi-1, self.hi - self.lo)
        self.data2 = np.zeros((self.sz,))
        self.leftThread  : 'Worker'
        self.rightThread : 'Worker'

    def recv_ghosts(self)->None:
        self.data[0] = self.left.get()
        self.data[-1] = self.right.get()

    def update(self)->None:
        self.recv_ghosts()

        self.data2[1:-1] = self.data[1:-1] + (k * dt / (dx * dx)) * (self.data[2:] + self.data[1:-1] + self.data[:-2])
        self.data, self.data2 = self.data2, self.data

        self.send_ghosts()

    def send_ghosts(self)->None:
        self.leftThread.right.put_nowait(self.data[0])
        self.rightThread.left.put_nowait(self.data[-1])

    def run(self)->None:
        self.send_ghosts()
        for n in range(nt):
            self.update()
        self.recv_ghosts()

def main()->Tuple[float,float]:
    th = []
    for num in range(threads):
        th += [Worker(num)]
    for i in range(threads):
        th[i].rightThread = th[(i+1) % threads]
        th[(i+1)%threads].leftThread = th[i]

    if use_hw_counters:
        high.start_counters([events.PAPI_FP_OPS,])

    t1 = time.time()
    for t in th:
        t.start()
    for t in th:
        t.join()
    t2 = time.time()

    hw : int
    if use_hw_counters:
        hw = high.stop_counters()
    else:
        hw = 0

    print(t2-t1)
    return t2-t1, hw

tdiff, hw = main()
fn = 'perfdata.csv'
if not os.path.exists(fn):
    with open(fn,"w") as fd:
        print('lang,nx,nt,threads,dt,dx,total time,flops',file=fd)
with open("perfdata.csv","a") as fd:
    print(",".join(
        [str(x) for x in ['heat2', nx, nt, threads, dx, dt, tdiff, hw]]
    ),file=fd)
