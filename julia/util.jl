function heat(left, middle, right, alpha)
    #return middle + (k * dt / (dx * dx)) * (left - 2 * middle + right)
    return middle + alpha * (left - 2 * middle + right)
end

function work(future, current, p, threads, nx, alpha)
    len = cld(nx, threads)
    start = p * len + 1 
    last = min((p+1) * len, nx)
    
    if p == threads-1
        last = nx 
    end

    n = length(current)
    @inbounds for i in start:last
        left_index = (i-2+n) % n + 1
        right_index = i % n + 1
        future[i] = heat(current[left_index],
                         current[i],
                         current[right_index],
                         alpha)
    end
    nothing
end