#  Copyright (c) 2023 AUTHORS
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. (See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#using Distributed
import Base.Threads;

check_correctness = false

const ghosts = 1
const nx = parse(Int64,ARGS[3])        # number of nodes
const k = 0.4                      # heat transfer coefficient
const dt = 1.                      # time step
const dx = 1.                      # grid spacing
const nt = parse(Int64,ARGS[2])        # number of time steps
const nthreads = parse(Int64,ARGS[1])    # numnber of threads    

const tx::Int64 = floor((2*ghosts+nx)/nthreads)

#Base.@kwdef mutable struct Worker

num::Int64 = -1 
lo::Int64 = tx * num - ghosts
hi::Int64 = tx * (num+1) + ghosts
sz::Int64 = hi - lo

#---- Start implement the queues---"
const qsize::Int64 = 12
qarray = zeros(Float64,2*qsize*nthreads) 
qhead = zeros(Int64,2*nthreads)
qtail = zeros(Int64,2*nthreads)
conds = Array{Threads.Condition,1}(undef,2*nthreads);
full = Array{Float64,1}(undef,nx);
for i in range(1,2*nthreads)
  conds[i] = Threads.Condition()
end
const leftq = 1
const rightq = 0

function push_queue(num, n, left_right, threadno, val)
    qno = left_right + 2 * threadno 
    t = qtail[qno+1]
    idx = qno * qsize + t % qsize + 1
    #print("push num: ",num," n: ",n,": qno=",qno," left_right=",left_right," threadno=", threadno," nthreads=",nthreads," idx=",idx," val=",val,"\n")
    qarray[idx] = val
    Threads.atomic_fence()
    diff = qtail[qno+1] - qhead[qno+1]
    Threads.atomic_fence()
    if diff == 0 
      c = conds[qno+1]
      lock(c)
      qtail[qno+1] += 1
      notify(c)
      unlock(c)
    else
      qtail[qno+1] += 1
    end
end

function pop_queue(n, left_right, threadno)
    qno = left_right + 2 * threadno 
    h = qhead[qno+1]
    idx = qno * qsize + h % qsize + 1
    t = qtail[qno+1]
    while h == t 
      c = conds[qno+1]
      lock(c)
      while h == t
          wait(c)
          t = qtail[qno+1]
      end
      unlock(c)
    end
    val = qarray[idx]
    #print("pop num: ",threadno," n: ",n,": qno=",qno," left_right=",left_right," threadno=", threadno," nthreads=",nthreads," idx=",idx," val=",val,"\n")
    qhead[qno+1] += 1
    return val
end

#---- End implement the queues---"

function work(num)
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

    for i in range(lo + off, lo + off + sz - 1)
        data[first][i - lo] = i 
    end

    # send
    push_queue(num,-1,rightq, im1, data[first][2])
    push_queue(num,-1,leftq, ip1, data[first][sz-1])
    for n in range(0,nt-1)
        data[first][1] = pop_queue(n, leftq, num)
        data[first][sz] = pop_queue(n,rightq, num)

        for i in range(2,sz-1)
            data[second][i] = data[first][i] + k*dt/(dx*dx)*(data[first][i+1] + data[first][i-1] - 2*data[first][i])
        end
        # swap
        first = 3 - first
        second = 3 - second

        push_queue(num,n,rightq, im1, data[first][2])
        push_queue(num,n,leftq, ip1, data[first][sz-1])
    end
    data[first][1] = pop_queue(nt,leftq, num)
    data[first][sz] = pop_queue(nt,rightq, num)
    for i in range(2,sz-1)
        full[i+lo] = data[first][i];
    end
end

totalTime = @elapsed begin
    Threads.@threads for i in 0:nthreads-1
        #println(i)
        work(i)
    end
end

if nx <= 20
  print("full:",full,"\n")
end

fn = "perfdata.csv"

if isfile(fn) == false
    file = open(fn, "w")
    write(file, "lang,nx,nt,threads,dt,dx,total time,flops\n")
    close(file)
end
file = open(fn, "a")
write(file, "julia"*","*string(nx)*","*string(nt)*","*string(nthreads)*","*string(dt)*","*string(dx)*","*string(totalTime)*","*string(0)*"\n")
close(file)
