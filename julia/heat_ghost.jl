#  Copyright (c) 2023 AUTHORS
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. (See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#using Distributed

println(PROGRAM_FILE)

check_correctness = false

ghosts = 1
nx = parse(Int64,ARGS[3])        # number of nodes
k = 0.4                      # heat transfer coefficient
dt = 1.                      # time step
dx = 1.                      # grid spacing
nt = parse(Int64,ARGS[2])        # number of time steps
nthreads = parse(Int64,ARGS[1])    # numnber of threads    

alp::Float64 = k*dt/(dx*dx)

tx::Int64 = floor.((2*ghosts+nx)/nthreads)
println(tx)

#Base.@kwdef mutable struct Worker

num::Int64 = -1 
lo::Int64 = tx * num - ghosts
hi::Int64 = tx * (num+1) + ghosts
sz::Int64 = hi - lo

#---- Start implement the queues---"
qsize::Int64 = 12
qarray = zeros(Float64,2*qsize*nthreads) 
qhead = zeros(Int64,2*nthreads)
qtail = zeros(Int64,2*nthreads)
leftq = 1
rightq = 0

function push_queue(left_right, threadno, val)
    qno = left_right + 2 * threadno 
    t = qtail[qno+1]
    idx = qno * qsize + t % qsize + 1
    #print("push: qno=",qno," left_right=",left_right," threadno=", threadno," nthreads=",nthreads," idx=",idx,"\n")
    qarray[idx] = val
    qtail[qno+1] += 1
end

function pop_queue(left_right, threadno)
    qno = left_right + 2 * threadno 
    h = qhead[qno+1]
    idx = qno * qsize + h % qsize + 1
    #print("pop: qno=",qno," left_right=",left_right," threadno=", threadno," nthreads=",nthreads," idx=",idx,"\n")
    t = qtail[qno+1]
    while h == t
        sleep(0)
        t = qtail[qno]
    end
    val = qarray[idx]
    qhead[qno+1] += 1
    return val
end

#---- End implement the queues---"

#@everywhere
function work0(num)
    print("Start work0: ",num,"\n")
end 

#@everywhere
function work(num)
    #print("Start work: ",num,"\n")
    first = 1
    second = 2
    lo::Int64 = tx*num
    hi::Int64 = tx*(num+1)
    if hi > nx
        hi = nx
    end
    lo -= ghosts
    hi += ghosts
    sz = hi - lo
    data = [zeros(Float64,sz),zeros(Float64,sz)]
    off = 1
    ip1 = (num + 1) % nthreads
    im1 = (num + nthreads - 1) % nthreads

    #print("Init work: ",num," sz: ",sz,"\n")
    for i in range(lo + off, lo + off + sz - 1)
        #print("Init loop: ",num," i: ",i," i-lo: ",i-lo,"\n")
        data[first][i - lo] = i 
    end
    #print("Post Init work: ",num,"\n")

    # send
    push_queue(rightq, im1, data[first][2])
    push_queue(leftq, ip1, data[first][sz-1])
    #print("Pre loop: ",num,"\n")
    for nt in range(1,nt)
        #print("nt: ",nt," ",data[first],"\n")
        data[first][1] = pop_queue(leftq, num)
        data[first][sz] = pop_queue(rightq, num)

        #print("Update: nt: ",nt," num: ",num,"\n")
        for i in range(2,sz-1)
            #print("Data i: ",i,"\n")
            data[second][i] = data[first][i] + alp*(data[first][i+1] + data[first][i-1] - 2*data[first][i])
        end
        #print("Post Update: nt: ",nt," num: ",num,"\n")
        push_queue(rightq, im1, data[first][2])
        push_queue(leftq, ip1, data[first][sz-1])
        # swap
        first = 3 - first
        second = 3 - second
    end
    #print("End Evo\n")
    data[first][1] = pop_queue(leftq, num)
    data[first][sz] = pop_queue(rightq, num)
    #print("Finis!",data[first],"\n")
end

totalTime = @elapsed begin
    #tasks = []
    #for i in 0:nthreads-1
    #    print("task: ",i+1)
    #    push!(tasks,@spawnat i+1 work(i))
    #end
    #for th in tasks
    #    wait(th)
    #end
    Threads.@threads for i in 0:nthreads-1
        #println(i)
        work(i)
    end
end
print("total time: ",totalTime,"\n")
