#  Copyright (c) 2023 AUTHORS
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. (See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
from threading import Thread
from queue import Queue
import numpy as np
import sys
import time
import os
#if sys.argv[4] == 1:
#    from pypapi import events, papi_high as high

nx = int(sys.argv[3])        # number of nodes
k = 0.5                      # heat transfer coefficient
dt = 1.                      # time step
dx = 1.                      # grid spacing
nt = int(sys.argv[2])        # number of time steps
threads = int(sys.argv[1])   # numnber of threads

tx = nx//threads

class Worker(Thread):
    def __init__(self,num):
        Thread.__init__(self)
        self.num = num
        self.lo = tx*num
        self.hi = tx*(num+1)
        if threads == 1:
            self.right = None
            self.left = None
        elif num+1 == threads:
            self.hi = nx
            self.right = None
            self.left = Queue()
        elif num == 0:
            self.left = None
            self.right = Queue()
        else:
            self.left = Queue()
            self.right = Queue()
        self.sz = self.hi - self.lo
        self.data = np.random.randn(self.sz)
        self.data2 = np.zeros((self.sz,))
        self.leftThread = None
        self.rightThread = None

    def recv_ghosts(self):
        if self.left is not None:
            self.data[0] = self.left.get()
        if self.right is not None:
            self.data[-1] = self.right.get()

    def update(self):
        self.recv_ghosts()

        self.data2[1:-1] = self.data[1:-1] + (k * dt / (dx * dx)) * (self.data[2:] + self.data[1:-1] + self.data[:-2])
        self.data, self.data2 = self.data2, self.data

        self.send_ghosts()

    def send_ghosts(self):
        if self.leftThread is not None:
            self.leftThread.right.put_nowait(self.data[0])
        if self.rightThread is not None:
            self.rightThread.left.put_nowait(self.data[-1])

    def run(self):
        self.send_ghosts()
        for n in range(nt):
            self.update()
        self.recv_ghosts()

def main():
    th = []
    for num in range(threads):
        th += [Worker(num)]
    for i in range(threads-1):
        th[i].rightThread = th[i+1]
        th[i+1].leftThread = th[i]
    t1 = time.time()
    for t in th:
        t.start()
    for t in th:
        t.join()
    t2 = time.time()
    print(t2-t1)
    return t2-t1

tdiff = main()
fn = 'perfdata.csv'
if not os.path.exists(fn):
    with open(fn,"w") as fd:
        print('lang,nx,nt,threads,dt,dx,total time,flops',file=fd)
with open("perfdata.csv","a") as fd:
    print(",".join(
        [str(x) for x in ['heat2', nx, nt, threads, dx, dt, tdiff, 0]]
    ),file=fd)
