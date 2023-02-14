//  Copyright (c) 2022 AUTHORS
//
//  SPDX-License-Identifier: BSL-1.0
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
import Foundation

let C_ARGV = CommandLine.arguments

let nx = Int(C_ARGV[3]) ?? -1  // number of nodes
let k = 0.5  // heat transfer coefficient
let dt = 1.0  // time step
let dx = 1.0  // grid spacing
let nt = Int(C_ARGV[2]) ?? -1  // number of time steps
let threads = Int(C_ARGV[1]) ?? -1  // numnber of threads

actor mesh {

private var space = Array(repeating: 0.0, count: nx)

func set_value( _ index : Int, _ value : Double)
{
 space[index] = value
}

func get_values() -> [Double]   {
    return space
}

}


func idx(_ i: Int, _ direction: Int) -> Int {

  if i == 0 && direction == -1 {
    return nx - 1
  }
  if i == nx - 1 && direction == +1 {
    return 0
  }
  assert((i + direction) < nx)

  return i + direction

}

func heat(left: Double, middle: Double, right: Double) -> Double {
  return middle + (k * dt / (dx * dx)) * (left - 2 * middle + right)
}

func work(_ current: [Double], _ p: Int, _ threads: Int) async -> [Double] {
  let length = Int(nx / threads)
  let start = p * length
  var end = (p + 1) * length - 1
  var future = Array(repeating: 0.0, count: length)

  if p == threads - 1 { end = nx - 1 }

  var index = 0
  for i in start...end {
    future[index] = heat(
      left: current[idx(i, -1)],
      middle:
        current[i], right: current[idx(i, +1)])
    index = index + 1
  }
  return future
}

var current = Array(repeating: 0.0, count: nx)
let future =  mesh()
for i in 0...(nx - 1) {
  current[i] = Double(i)
}

for t in 0...(nt - 1) {

  await withTaskGroup(
    of: [Double].self, returning: Void.self,
    body: {

      group in

      for p in 0...(threads - 1) {
        group.addTask { await work(current, p, threads) }
      }


      for await result in group {

        var i = 0 
        for e in result {
          await future.set_value(i,e)
          i = i + 1
        }
      }

    }
  )
  await current = future.get_values();
}

