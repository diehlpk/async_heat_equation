#  Copyright (c) 2023 AUTHORS
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. (See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

using FastBroadcast
using BenchmarkTools

# function of seting up the I.C.
function init_space(nx;nghost=1)
    space = [collect(Float64,1:1:nx+2*nghost), collect(Float64,1:1:nx+2*nghost)]
    return space
end

function benchmark(nt::Int, space::Vector{Vector{T}}, nthreads::Int, nx::Int, α::T; nghost=1) where T
    for t in range(1, nt)
        # swap the array for next time iteration
        ∂u∂t_next = isodd(t) ? space[1] :  space[2];
        ∂u∂t      = isodd(t) ? space[2] :  space[1];
        # swap the periodic boundary
        copyto!(view(∂u∂t,           1:nghost     ), view(∂u∂t,      nx+1:nx+nghost));
        copyto!(view(∂u∂t, nx+nghost+1:nx+2*nghost), view(∂u∂t,  nghost+1:2*nghost ));
        # Actual Advection
        work!(∂u∂t_next, ∂u∂t, nx, α, nghost, nthreads)
    end
    ∂u∂t_next = isodd(nt) ? space[1] :  space[2];
    return ∂u∂t_next
end

function work!(∂uᵢ∂t_next::Array{T,1},  ∂uᵢ∂t::Array{T,1}, nx::Int, α::T, nghost::Int, nthreads::Int) where T
    is, ie = nghost + 1 , nx + nghost
    heat!(∂uᵢ∂t_next, ∂uᵢ∂t, α, is, ie, nthreads)
    return nothing
end

@inbounds function heat!(∂uᵢ∂t_next::Array{T,1}, ∂uᵢ∂t::Array{T,1}, α::T, is::Int, ie::Int, nthreads::Int) where T
    @.. thread=true ∂uᵢ∂t_next[is:ie] = ∂uᵢ∂t[is:ie] + α * ( ∂uᵢ∂t[is-1:ie-1] - 2 * ∂uᵢ∂t[is:ie] + ∂uᵢ∂t[is+1:ie+1])
    return nothing;
end

nx = parse(Int64,ARGS[3])       # number of nodes
k = 0.4                         # heat transfer coefficient
dt = 1.0                        # time step
dx = 1.0                        # grid spacing
alpha = k*dt/(dx*dx)            # alpha
nt = parse(Int64,ARGS[2])       # number of time steps
nthreads = parse(Int64,ARGS[1]) # number of threads  

totalTime = @belapsed benchmark($nt, space, $nthreads, $nx, $alpha) setup=(space=init_space($nx))

fn = "perfdata.csv"

if isfile(fn) == false
    file = open(fn, "w")
    write(file, "lang,nx,nt,threads,dt,dx,total time,flops\n")
    close(file)
end
file = open(fn, "a")
write(file, PROGRAM_FILE*","*string(nx)*","*string(nt)*","*string(nthreads)*","*string(dt)*","*string(dx)*","*string(totalTime)*","*string(0)*"\n")
close(file)
