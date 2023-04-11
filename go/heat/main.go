//  Copyright (c) 2023 AUTHORS
//
//  SPDX-License-Identifier: BSL-1.0
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

package main

import (
	"fmt"
	"heat/impl"
	"os"
	"strconv"
	"time"
)

func main() {
	if len(os.Args) < 4 {
		panic("Not enough arguments.")
	}

	threads, err := strconv.Atoi(os.Args[1])
	if err != nil {
		panic("Arg threads not convertible.")
	}

	nt, err := strconv.Atoi(os.Args[2])
	if err != nil {
		panic("Arg nt not convertible.")
	}

	nx, err := strconv.Atoi(os.Args[3])
	if err != nil {
		panic("Arg nx not convertible.")
	}

	var state = impl.NewState(nx, nt, threads)
	var start = time.Now()

	state.Work()

	err = logCsv(state, time.Since(start))
	if err != nil {
		panic("Couldn't write perfdata.csv: " + err.Error())
	}
}

func logCsv(s *impl.State, elapsed time.Duration) error {
	var fileName = "perfdata.csv"

	if _, err := os.Stat(fileName); os.IsNotExist(err) {
		file, err := os.Create(fileName)

		if err != nil {
			return err
		}

		defer file.Close()

		_, err = file.WriteString("lang,nx,nt,threads,dt,dx,seconds\n")

		if err != nil {
			return err
		}
	}

	file, err := os.OpenFile(fileName, os.O_APPEND|os.O_WRONLY, 0644)

	if err != nil {
		return err
	}

	defer file.Close()

	_, err = file.WriteString(fmt.Sprintf("go,%d,%d,%d,%g,%g,%f\n", s.Nx, s.Nt, s.Threads, impl.DT, impl.DX, elapsed.Seconds()))

	return err
}
