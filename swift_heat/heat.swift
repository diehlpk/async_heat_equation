//  Copyright (c) 2022 AUTHORS
//
//  SPDX-License-Identifier: BSL-1.0
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
let C_ARGV = CommandLine.arguments

let nx = Int(C_ARGV[3]) ?? -1        // number of nodes
let k = 0.5                         // heat transfer coefficient
let dt = 1.0                        // time step
let dx = 1.0                        // grid spacing
let nt = Int(C_ARGV[2]) ?? -1        // number of time steps
let threads = Int(C_ARGV[1]) ?? -1  // numnber of threads

func idx(i: Int, direction: Int) -> Int {

    if (i == 0 && direction == -1)
    { 
        return nx - 1
    }
    if (i == nx - 1 && direction == +1)
    {
        return 0
    }
    assert ((i + direction) < nx)

    return i + direction

}

func heat(left: Double, middle: Double, right: Double) -> Double
{
    return middle + (k * dt / (dx * dx)) * (left - 2 * middle + right)
}
