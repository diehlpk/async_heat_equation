//  Copyright (c) 2022 AUTHORS
//
//  SPDX-License-Identifier: BSL-1.0
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
var ncount = 0.0

// Ask the user for the nummber of iterations
print("Please enter the number of iterations:")
let end = Int(readLine()!)!

// Loop over the iterations
for _ in 1...end {

    let xVar = Double.random(in: 0...1)
    let yVar = Double.random(in: 0...1)
 
    if xVar * xVar + yVar * yVar  <= 1.0 {
        ncount += 1
    }
}

// Compute the final result
var pi_estimate = 4.0 * ncount / Double(end)

// Print the final result
print(" Pi is equal to \(pi_estimate) after \(end) iterations")
