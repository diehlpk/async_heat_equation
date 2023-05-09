//  Copyright (c) 2023 AUTHORS
//
//  SPDX-License-Identifier: BSL-1.0
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

package impl

import (
	"heat_mini/util"
	"math"
	"sync"
)

const (
	K  float64 = 0.4
	DT float64 = 1
	DX float64 = 1

	ConstantHeatTerm = K * DT / (DX * DX)

	channelBufferSize = 12
)

func heat(left float64, middle float64, right float64) float64 {
	return middle + ConstantHeatTerm*(left-2.0*middle+right)
}

type GridChunk []float64

type State struct {
	parts       [][2]GridChunk
	leftGhosts  []chan float64
	rightGhosts []chan float64
	Nx          int
	Nt          int
	Threads     int
}

func NewState(nx int, nt int, threads int) *State {
	var initialGrid = make(GridChunk, nx)

	for i := 0; i < nx; i++ {
		initialGrid[i] = float64(i + 1)
	}

	var parts = make([][2]GridChunk, threads)
	var chunks = util.Chunks(initialGrid, int(math.Ceil(float64(nx)/float64(threads))))

	for i, e := range chunks {
		var auxPart = make(GridChunk, len(e))
		var mainAndAux = [2]GridChunk{e, auxPart}
		parts[i] = mainAndAux
	}

	var leftGhosts = make([]chan float64, threads)
	var rightGhosts = make([]chan float64, threads)

	for i := range leftGhosts {
		leftGhosts[i] = make(chan float64, channelBufferSize)
		rightGhosts[i] = make(chan float64, channelBufferSize)
	}

	return &State{
		parts:       parts,
		leftGhosts:  leftGhosts,
		rightGhosts: rightGhosts,
		Nx:          nx,
		Nt:          nt,
		Threads:     threads,
	}
}

func (this *State) Work() {
	var waitGroup sync.WaitGroup
	waitGroup.Add(this.Threads)

	for threadNum := 0; threadNum < this.Threads; threadNum++ {

		//region Per-thread state

		var myPart = this.parts[threadNum]
		var leftTx = this.leftGhosts[threadNum]
		var rightTx = this.rightGhosts[threadNum]

		var leftRx chan float64
		if threadNum == 0 {
			leftRx = this.rightGhosts[this.Threads-1]
		} else {
			leftRx = this.rightGhosts[threadNum-1]
		}

		var rightRx chan float64
		if threadNum == this.Threads-1 {
			rightRx = this.leftGhosts[0]
		} else {
			rightRx = this.leftGhosts[threadNum+1]
		}

		//endregion Per-thread state

		go func(myPart *[2]GridChunk, leftTx chan float64, rightTx chan float64, leftRx chan float64, rightRx chan float64, nt int, wg *sync.WaitGroup) {
			var chunkLen = len(myPart[0])

			var current = (*myPart)[0]
			var aux = (*myPart)[1]

			for t := 0; t < nt; t++ {
				leftTx <- current[0]
				rightTx <- current[chunkLen-1]

				aux[0] = heat(<-leftRx, current[0], current[1])
				aux[chunkLen-1] = heat(current[chunkLen-2], current[chunkLen-1], <-rightRx)

				for idx := 1; idx < chunkLen-1; idx++ {
					aux[idx] = heat(current[idx-1], current[idx], current[idx+1])
				}

				current, aux = aux, current
			}

			wg.Done()
		}(&myPart, leftTx, rightTx, leftRx, rightRx, this.Nt, &waitGroup)
	}

	waitGroup.Wait()
}

func (this *State) CollectSpace() []float64 {
	var v = make([]float64, 0, this.Nx)

	for _, part := range this.parts {
		for _, elem := range part[this.Nt%2] {
			v = append(v, elem)
		}
	}

	return v
}
