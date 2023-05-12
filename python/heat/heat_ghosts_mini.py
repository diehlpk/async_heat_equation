#  Copyright (c) 2023 AUTHORS
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. (See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
from typing import Optional, Tuple, List
from threading import Thread
from queue import Queue
import numpy as np
import sys
import time
import os

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

def main(nthreads : int)->Tuple[float,float,np.ndarray]:
    th = []
    tx = (2*ghosts+nx)//nthreads
    assert tx > 0
    for num in range(nthreads):
        th += [Worker(num,tx)]
    for i in range(nthreads):
        th[i].rightThread = th[(i+1) % nthreads]
        th[(i+1)%nthreads].leftThread = th[i]

    t1 = time.time()
    for t in th:
        t.start()
    for t in th:
        t.join()
    t2 = time.time()
