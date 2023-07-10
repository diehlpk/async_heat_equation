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
    left_value = current[(start-2+n) % n + 1]
    right_value = current[start]
    @inbounds for i in start:last
        middle_value = right_value
        right_value = current[i % n + 1]
        future[i] = heat(left_value,
                         middle_value,
                         right_value,
                         alpha)
        left_value = middle_value
    end
    nothing
end