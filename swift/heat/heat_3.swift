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

struct Worker {

  let space: [UnsafeMutableBufferPointer<Double>]
  var num: Int
  var lo: Int
  var hi: Int

  init(_ p_num: Int, _ tx: Int) {

    num = p_num
    lo = tx * num
    hi = tx * (num + 1)

    space = [
      UnsafeMutableBufferPointer<Double>.allocate(capacity: num),
      UnsafeMutableBufferPointer<Double>.allocate(capacity: num),
    ]

    for i in 0...(num-1)
    {
      space[0][i] = Double(lo + i)
    }

  }

 func update(_ t : Int) {

  let r = (k * dt / (dx * dx))

  for i in 1...(num-2){

     space[(t + 1) % 2][i] =
                (space[t % 2][i]
                  + r
                    * (space[t % 2][nx - 1] - 2 * space[t % 2][i] + space[t % 2][i + 1]))
  }


  }

func send_left (_ t : Int) -> Double {

return space[t % 2][0]

  }

 func send_right (_ t : Int) -> Double {

  return space[t % 2][num-1]

  }

  func receive_left () {}

  func recieve_left () {}

}

var workerPool : [ Worker ] = []
let length = Int(nx / threads)

for t in 0...(threads - 1) {

  workerPool.append(Worker(length,t))
  
} 

for t in 0...(nt - 1) {

  await withTaskGroup(
    of: Void.self, returning: Void.self,
    body: { group in

      for p in 0...(threads - 1) {

        group.addTask {

          
            await workerPool[p].update(t)



        
          }

        }

      
      for await _ in group {

      }

    })

}



print("swift,\(nx),\(nt),\(threads),\(dt),\(dx),\(-start.timeIntervalSinceNow)")


