// This file is part of the Monte carlo code exmaples.
// Copyright (c) 2021 Patrick Diehl
// 
// This program is free software: you can redistribute it and/or modify  
// it under the terms of the GNU General Public License as published by  
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful, but 
// WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program. If not, see <http://www.gnu.org/licenses/>.

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
