#  Copyright (c) 2023 AUTHORS
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. (See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#using DataStructures
#using Distributed

include("util.jl")

workers = Threads.nthreads()

nx = parse(Int64,ARGS[3])        # number of nodes
k = 0.4                      # heat transfer coefficient
dt = 1.                      # time step
dx = 1.                      # grid spacing
alp = k*dt/(dx*dx)             # alpha
nt = parse(Int64,ARGS[2])        # number of time steps
nthreads = parse(Int64,ARGS[1])    # numnber of threads  

space = [zeros(nx), zeros(nx)]

for i in range(1, nx)
    space[1][i] = i
end

totalTime = @elapsed begin
    for t in range(1, nt)
        current = space[t % 2+1]
        future = space[(t+1) % 2+1]

        Threads.@threads for i in 0:nthreads-1
            work(future,current,i,nthreads,nx,alp)
        end
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
