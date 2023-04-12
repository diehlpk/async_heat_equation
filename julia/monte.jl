#  Copyright (c) 2023 AUTHORS
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. (See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#import RandomNumbers

ncount = 0.0

# Ask the user for the nummber of iterations
print("Please enter the number of iterations:")
n = parse(Int64,readline())

#  Loop over the iterations
for _ in 1:n
    xVar = rand() * 2 -1
    yVar = rand() * 2 -1

    if xVar * xVar + yVar * yVar <= 1
        global ncount += 1
    end
end

# Compute the final result
pi = 4.0 * ncount / n

# Print the final result
print(" Pi is equal to $pi  after $n iterations")
