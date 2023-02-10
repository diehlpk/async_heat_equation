#  Copyright (c) 2023 AUTHORS
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. (See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
import random

ncount = 0.0

# Ask the user for the nummber of iterations
end = int(input("Please enter the number of iterations:"))

#  Loop over the iterations
for _ in range(end):
    xVar = random.uniform(0,1)
    yVar = random.uniform(0,1)

    if xVar * xVar + yVar * yVar <= 1:
        ncount +=1 

# Compute the final result
pi = 4.0 * ncount / end

# Print the final result
print(" Pi is equal to " + str(pi) + " after " + str(end) + " iterations")

