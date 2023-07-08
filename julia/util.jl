function heat(left, middle, right, alpha)
    #return middle + (k * dt / (dx * dx)) * (left - 2 * middle + right)
    return middle + alpha * (left - 2 * middle + right)
end

function work(future, current, p, threads, nx, alpha)
    len = cld(nx, nthreads)
    start = p * len + 1 
    last = minimum((p+1) * len, nx)

    if p == threads-1
        last = nx 
    end

    n = length(current)
    @inbounds @simd for i in range(start, last)
        future[i] = heat(current[(i-1)%n+1],
                         current[i], current[(i+1)%n+1],
                         alpha)
    end
end
