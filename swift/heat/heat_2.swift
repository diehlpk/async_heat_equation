//  Copyright (c) 2022 AUTHORS
//
//  SPDX-License-Identifier: BSL-1.0
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
import Foundation

let start = Date()

let C_ARGV = CommandLine.arguments

let nx = Int(C_ARGV[3]) ?? -1  // number of nodes
let k = 0.5  // heat transfer coefficient
let dt = 1.0  // time step
let dx = 1.0  // grid spacing
let nt = Int(C_ARGV[2]) ?? -1  // number of time steps
let threads = Int(C_ARGV[1]) ?? -1  // numnber of threads

let space = [
  UnsafeMutableBufferPointer<Double>.allocate(capacity: nx),
  UnsafeMutableBufferPointer<Double>.allocate(capacity: nx),
]

space[1].initialize(repeating: 0)
space[0].initialize(repeating: 0)

for i in 0...(nx - 1) {
  space[0][i] = Double(i)
}

for t in 0...(nt - 1) {

  await withTaskGroup(
    of: Void.self, returning: Void.self,
    body: { group in

      for p in 0...(threads - 1) {

        group.addTask {

          let length = Int(nx / threads)
          let start = p * length
          var end = (p + 1) * length - 1

          if p == threads - 1 { end = nx - 1 }

          let r = (k * dt / (dx * dx))

          // space[(t + 1) % 2][i].addingProduct(lhs: Double, rhs: Double)

          for i in start...end {

            if i == 0 {

              space[(t + 1) % 2][i] =
                (space[t % 2][i]
                  + r
                  * (space[t % 2][nx - 1] - 2 * space[t % 2][i] + space[t % 2][i + 1]))

            }

            else if i == nx - 1 {

              space[(t + 1) % 2][i] =
                (space[t % 2][i]
                  + r
                  * (space[t % 2][i - 1] - 2 * space[t % 2][i] + space[t % 2][0]))

            }

            else {

              space[(t + 1) % 2][i] =
                (space[t % 2][i]
                  + r
                  * (space[t % 2][i - 1] - 2 * space[t % 2][i] + space[t % 2][i + 1]))
            }
          }

        }

      }
      for await _ in group {

      }

    })

}

//for i in 0...(nx-1){
//  print(space[0][i],space[1][i])
//}

print("swift,\(nx),\(nt),\(threads),\(dt),\(dx),\(-start.timeIntervalSinceNow)")
