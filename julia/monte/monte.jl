#  Copyright (c) 2023 AUTHORS
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. (See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)


# Ask the user for the nummber of iterations
print("Please enter the number of iterations:")
n = parse(Int64,readline())

#  Loop over the iterations
function calculate_pi_serial(n, type=Float64)
    ncount = zero(type)
    for _ in 1:n
        xVar = rand(type) * 2 - 1
        yVar = rand(type) * 2 - 1

        if xVar * xVar + yVar * yVar <= 1
            ncount += 1
        end
    end
    return 4 * ncount / n
end

# Compute the final result
pi_est = calculate_pi_serial(n, Float64)

# Print the final result
println(" Pi is equal to $pi_est  after $n iterations")
