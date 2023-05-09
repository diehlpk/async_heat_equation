//  Copyright (c) 2023 AUTHORS
//
//  SPDX-License-Identifier: BSL-1.0
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

package main

import (
	"fmt"
	"heat_mini/impl"
	"os"
	"strconv"
	"time"
)

func main() {
	threads, _ := strconv.Atoi(os.Args[1])
	nt, _ := strconv.Atoi(os.Args[2])
	nx, _ := strconv.Atoi(os.Args[3])

	var state = impl.NewState(nx, nt, threads)
	var start = time.Now()

	state.Work()

	var elapsed = time.Since(start)
	fmt.Printf("go,%d,%d,%d,%g,%g,%f\n", state.Nx, state.Nt, state.Threads, impl.DT, impl.DX, elapsed.Seconds())

	if nx <= 20 {
		fmt.Printf("Final grid (NX = %d): %v\n", nx, state.CollectSpace())
	}
}
