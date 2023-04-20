nx = 100000
k = 0.5
dt = 1
dx = 1

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