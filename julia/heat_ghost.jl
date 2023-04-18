#  Copyright (c) 2023 AUTHORS
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. (See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
using DataStructures

println(PROGRAM_FILE)

check_correctness = false

ghosts = 1
nx = parse(Int64,ARGS[3])        # number of nodes
k = 0.5                      # heat transfer coefficient
dt = 1.                      # time step
dx = 1.                      # grid spacing
nt = parse(Int64,ARGS[2])        # number of time steps
nthreads = parse(Int64,ARGS[1])    # numnber of threads    

Base.@kwdef mutable struct Worker

num::Int64 = -1 
tx::Int64 = -1
lo::Int64 = tx * num - ghosts
hi::Int64 = tx * (num+1) + ghosts
sz::Int64 = hi -lo

#@assert sz > 0

#right::Queue[Float64] = Queue[Float64]()
#left::Queue[Float64] = Queue[Float64]()

off = 1

data = lo+off:(hi-1+off)/(hi-lo):(hi-1+off)
data2 = zeros(sz,1)

leftThread::Worker = Worker(num=-1,tx=-1)
rightThread::Worker = Worker(num=-1,tx=-1)

end

function recv_ghosts(w::Worker)

w.data[0] = w.left.get()
w.data[-1] = w.right.get()

end

function update(w::Worker)

    recv_ghosts(w)

    #w.data2[1:-1] = w.data[1:-1] + (k * dt / (dx * dx)) * (w.data[2:] - 2*w.data[1:-1] + w.data[:-2])
    #w.data w.data2 = w.data2, w.data

end

function send_ghosts(w::Worker)

    enqueue!(w.leftThread.right,w.data[1])
    enqueue!(w.rightThread.left,w.data[1-2])

end

function run(w::Worker)

    send_ghosts(w)

    for n in range(nt)
        update(w)
    end

    recv_ghosts(w)
end

function construct_grid(th::Array{Worker})

    total = zeros(nx,1)
    for t in th 
        total[t.lo + ghosts:t.hi - ghosts] = t.data[ghosts:-ghosts]
    end

    #print("Stats:",np.min(total),np.average(total),np.max(total))
    return total
end

# main
Base.zero(::Worker) = Worker(num=-1,tx=-1)
Base.zero(::Type{Worker}) = Worker(num=-1,tx=-1)

th = zeros(Worker,nthreads)

#Vector{Worker}(Worker(num=-1,tx=-1),nthreads)

tx = (2*ghosts+nx)


for num in range(1,nthreads)
   #println(size(th))
   #th[Int(num)] = Worker(num = nx,tx=tx)
   #push!(th,Worker(num = nx,tx=tx))
   #insert!(th,num,Worker(num = nx,tx=tx))
end

println("end")

#for i in range(1,nthreads)
#    th[i].rightThread = th[(i+1) % nthreads + 1]q
#    #th[(i+1)%nthreads+1].leftThread = th[i]
#end

#tasks = []

#t1 = time.time()
#for t in th
#    task = @task run(t)
#    schedule(task)
#    push!(tasks,task)
#end
#for task in tasks 
#    wait(task)
#end
#t2 = time.time()