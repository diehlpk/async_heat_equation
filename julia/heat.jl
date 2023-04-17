#  Copyright (c) 2023 AUTHORS
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. (See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
using DataStructures

println(PROGRAM_FILE)

check_correctness = false

ghosts = 1
nx = parse(Int64,ARGS[2])        # number of nodes
k = 0.5                      # heat transfer coefficient
dt = 1.                      # time step
dx = 1.                      # grid spacing
nt = parse(Int64,ARGS[1])        # number of time steps
threads = Threads.nthreads()   # numnber of threads    

Base.@kwdef mutable struct Worker

num::Int64   
lo::Int64 = num - ghost
hi::Int64 = (num+1) + ghosts
sz::Int64 = hi -lo

right::Queue = Queue[Float64]()
left::Queue = Queue[Float64]()

off = 1

data = lo+off:(hi-1+off)/(hi-lo):(hi-1+off)
data2 = zeros(sz,1)

leftThread::Worker
rightThread::Worker

end

function recv_ghosts(w::Worker)

w.data[0] = w.left.get()
w.data[-1] = w.right.get()

end

function update(w::Worker)

    w.recv_ghosts()

    #w.data2[1:-1] = w.data[1:-1] + (k * dt / (dx * dx)) * (w.data[2:] - 2*w.data[1:-1] + w.data[:-2])
    #w.data w.data2 = w.data2, w.data

end

function send_ghosts(w::Worker)

    enqueue!(w.leftThread.right,w.data[1])
    enqueue!(w.rightThread.left,w.data[1-2])

end

function run(w::Worker)

    w.send_ghosts()

    for n in range(nt)
        w.update()
    end

    w.recv_ghosts()
end

function construct_grid(th::Array{Worker})

    total = zeros(nx,1)
    for t in th 
        total[t.lo + ghosts:t.hi - ghosts] = t.data[ghosts:-ghosts]
    end

    #print("Stats:",np.min(total),np.average(total),np.max(total))
    return total
end

