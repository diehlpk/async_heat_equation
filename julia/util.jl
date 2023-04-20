function heat(left, middle, right, alp)
    #return middle + (k * dt / (dx * dx)) * (left - 2 * middle + right)
    return middle + alp * (left - 2 * middle + right)
end

function work(future, current, p, threads, nx, alp)
    len = Int(round(nx / threads))
    start = p * len + 1 
    last = (p+1) * len 

    if p == threads-1
        last = nx 
    end

    n = length(current)
    for i in range(start, last)
        future[i] = heat(current[(i-1)%n+1],
                         current[i], current[(i+1)%n+1],
                         alp)
    end
end
