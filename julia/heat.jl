#  Copyright (c) 2023 AUTHORS
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. (See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
using DataStructures

check_correctness = false

nx = parse(Int64,ARGS[3])        # number of nodes
k = 0.5                      # heat transfer coefficient
dt = 1.                      # time step
dx = 1.                      # grid spacing
nt = parse(Int64,ARGS[2])        # number of time steps
nthreads = parse(Int64,ARGS[1])    # numnber of threads   

function idx(i, direction)

    if i == 0 && direction == -1
        return nx - 1
    end

    if i == nx - 1 && direction == +1
        return 0

    end

    @assert ((i + direction) < nx)

    return i + direction

end

function heat(left, middle, right)

    return middle + (k * dt / (dx * dx)) * (left - 2 * middle + right)
end

function work(future, current, p,threads)
    len = Int(round(nx / threads))
    start = p * len + 1 
    last = (p+1) * len 

    if p == threads-1
        last = nx 
    end

    n = length(current)
    for i in range(start, last)
        future[i] = heat(current[(i-1)%n+1],
                         current[i], current[(i+1)%n+1])
    end
    
end



space = [zeros(nx), zeros(nx)]

for i in range(1, nx)
    space[1][i] = i
end

totalTime = @elapsed begin

for t in range(1, nt)
    current = space[t % 2+1]
    future = space[(t+1) % 2+1]

    #tasks = []
  
    #for i in 0:nthreads-1
    #    push!(tasks,Threads.@spawn work(future,current,i,nthreads))
    #end

    Threads.@threads for i in 0:9
        work(future,current,i,nthreads)    
    end

    #for t in tasks
    #    wait(t)
    #end
end

end

fn = "perfdata.csv"

if isfile(fn) == false
   
    file = open(fn, "w")
    write(file, "lang,nx,nt,threads,dt,dx,total time,flops\n")
    close(file)
end
file = open(fn, "a")
write(file, PROGRAM_FILE*","*string(nx)*","*string(nt)*","*string(nthreads)*","*string(dt)*","*string(dx)*","*string(totalTime)*","*string(0)*"\n")
close(file)