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

actor partition {

  private var current: [[Double]]
  private var future: [[Double]]

  init() {

    current = []
    future = []

  }

  func append_current(_ element: [Double]) {

    current.append(element)

  }

  func append_future(_ element: [Double]) {

    future.append(element)

  }

  func get_current(_ index: Int) -> [Double] {
    return current[index]
  }

  func get_future(_ index: Int) -> [Double] {
    return future[index]
  }

  func set_future(_ index: Int, _ pos: Int, _ value: Double) {
    future[index][pos] = value

  }

  func set_current(_ index: Int, _ pos: Int, _ value: Double) {
    current[index][pos] = value

  }

  func swap(_ index: Int) {
    current[index] = future[index]
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

func work(_ part: partition, _ p: Int, _ threads: Int) async -> Int {

  var length = Int(nx / threads)

  if p == threads - 1 { length = nx - p * length }

  for i in 1...(length - 2) {
    await part.set_future(
      p, i,
      heat(
        left: part.get_current(p)[i - 1],
        middle: part.get_current(p)[i],
        right: part.get_current(p)[i + 1]))

  }

  return p

}

let part = partition()

var length = Int(nx / threads)

for p in 0...(threads - 1) {

  let start = p * length
  var end = (p + 1) * length

  if p == (threads - 1) {
    length = nx - p * threads
    end = nx
  }

  await part.append_current(Array(repeating: 0.0, count: length))

  var index = 0
  for i in start...(end - 1) {
    await part.set_current(p, index, Double(i))

    index += 1
  }

  await part.append_future(Array(repeating: 0.0, count: length))

}

for _ in 0...(nt - 1) {

  await withTaskGroup(
    of: Int.self, returning: Void.self,
    body: {

      group in

      for p in 0...(threads - 1) {

        group.addTask { await work(part, p, threads) }
      }

      for await result in group {

        if result == 0 {
          await part.set_future(
            result, 0,
            heat(
              left: part.get_current(threads - 1)[nx - 1 - ((threads - 1) * Int(nx / threads))],
              middle: part.get_current(result)[0],
              right: part.get_current(result)[1]))

          await part.set_future(
            result, Int(nx / threads) - 1,
            heat(
              left: part.get_current(result)[Int(nx / threads) - 2],
              middle: part.get_current(result)[Int(nx / threads - 1)],
              right: part.get_current(threads - 1 - result)[0]))
        }

        if result == (threads - 1) && threads > 1 {

          await part.set_future(
            result, 0,
            heat(
              left: part.get_current(threads - 2)[nx - 1 - ((threads - 1) * Int(nx / threads))],
              middle: part.get_current(result)[0],
              right: part.get_current(result)[1]))

          await part.set_future(
            result, Int(nx / threads) - 1,
            heat(
              left: part.get_current(result)[Int(nx / threads) - 2],
              middle: part.get_current(result)[Int(nx / threads - 1)],
              right: part.get_current(threads - 1 - result)[0]))

        }

      }

    }

  )

  for i in 0...(threads - 1) {
    await part.swap(i)
  }

}
