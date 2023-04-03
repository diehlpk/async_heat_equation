#  Copyright (c) 2023 AUTHORS
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. (See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
from typing import Optional, Tuple, List, TypeVar, Generic
from threading import Thread, Lock, Condition
#from queue import Queue
import numpy as np
import sys
import time
import os

T = TypeVar('T')

class Queue(Generic[T]):
    def __init__(self):
        self.lock = Lock()
        self.items : List[T] = []
    def put_nowait(self, item: T)->None:
        with self.lock:
            self.items += [item]
    def get(self)->T:
        while True:
            with self.lock:
                if len(self.items)>0:
                    item = self.items[-1]
                    self.items = self.items[:-1]
                    return item
        time.sleep(1e-13)

use_hw_counters : bool = sys.argv[4] == "1"

check_correctness = False

if use_hw_counters:
    from pypapi import events, papi_high as high

ghosts = 1
nx = int(sys.argv[3])        # number of nodes
k = 0.4                      # heat transfer coefficient
dt = 1.                      # time step
dx = 1.                      # grid spacing
nt = int(sys.argv[2])        # number of time steps
threads = int(sys.argv[1])   # numnber of threads

class Worker(Thread):
    def __init__(self,num:int,tx:int)->None:
        Thread.__init__(self)
        self.num : int = num
        self.lo : int = tx*num
        self.hi : int = tx*(num+1)
        if self.hi > nx:
            self.hi = nx
        self.lo -= ghosts
        self.hi += ghosts
        self.right : Queue[float] = Queue()
        self.left : Queue[float] = Queue()
        self.sz = self.hi - self.lo
        assert self.sz > 0
        off = 1
        self.data = np.linspace(self.lo+off, self.hi-1+off, self.hi - self.lo)
        self.data2 = np.zeros((self.sz,))
        assert self.data.shape == self.data2.shape
        self.leftThread  : 'Worker'
        self.rightThread : 'Worker'

    def recv_ghosts(self)->None:
        self.data[0] = self.left.get()
        self.data[-1] = self.right.get()

    def update(self)->None:
        self.recv_ghosts()

        self.data2[1:-1] = self.data[1:-1] + (k * dt / (dx * dx)) * (self.data[2:] - 2*self.data[1:-1] + self.data[:-2])
        self.data, self.data2 = self.data2, self.data

        self.send_ghosts()

    def send_ghosts(self)->None:
        self.leftThread.right.put_nowait(self.data[1])
        self.rightThread.left.put_nowait(self.data[-2])

    def run(self)->None:
        self.send_ghosts()
        for n in range(nt):
            self.update()
        self.recv_ghosts()

def construct_grid(th:List[Worker]) -> np.ndarray:
    total = np.zeros((nx,))
    for t in th:
        total[t.lo + ghosts:t.hi - ghosts] = t.data[ghosts:-ghosts]

    print("Stats:",np.min(total),np.average(total),np.max(total))
    return total
    
def main(nthreads : int)->Tuple[float,float,np.ndarray]:
    th = []
    tx = (2*ghosts+nx)//nthreads
    assert tx > 0
    for num in range(nthreads):
        th += [Worker(num,tx)]
    for i in range(nthreads):
        th[i].rightThread = th[(i+1) % nthreads]
        th[(i+1)%nthreads].leftThread = th[i]

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

    total = construct_grid(th)
    avg0 = (nx+1)/2
    avgN = np.average(total)

    if nx < 20:
        print("grid:",total)
    print("time for ",nthreads,": ",t2-t1,sep="")
    err = np.abs(avgN - avg0)
    if err > 1e-13:
        print(f"{avgN} != {avg0}, err={err}")
    return t2-t1, hw, total

if check_correctness:
    tdiff, hw, data1 = main(1)
tdiff, hw, dataN = main(threads)
if check_correctness:
    print("diff check:",np.max(np.abs(dataN - data1)))
fn = 'perfdata.csv'
if not os.path.exists(fn):
    with open(fn,"w") as fd:
        print('lang,nx,nt,threads,dt,dx,total time,flops',file=fd)
with open("perfdata.csv","a") as fd:
    print(",".join(
        [str(x) for x in ['heat2', nx, nt, threads, dx, dt, tdiff, hw]]
    ),file=fd)
