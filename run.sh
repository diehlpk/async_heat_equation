#!/usr/bin/bash

source "$HOME/.cargo/env"
CHARM_DIR=/work/diehlpk/Compile/medusa/charm/bin/
module load gcc/12.2.0
module load python/3.10.5

PYTHON=0
SWIFT=0
RUST=0
GO=0
CHAPEL=0
CXX=0
JULIA=0
CHARM=0
HPX=1

TIME=1000
SIZE=1000000

if [ "${PYTHON}" == "1" ]
then

    cd python

    for i in {40..0..2}
    do 
        python3.10 heat2.py $i ${TIME} ${SIZE} 0 
    done

    cd ..

fi

if [ "${SWIFT}" == "1" ]
then
    cd swift/heat

    for i in {40..0..2}
    do 
        ./heat_3 $i ${TIME} ${SIZE} >> perfstat.csv
    done

    cd ../..
fi


if [ "${RUST}" == "1" ]
then
    cd rust/heat_simd/target/release

    for i in {40..0..2}
    do 
        ./heat_simd $i ${TIME} ${SIZE}
    done

    cd ../../../..
fi


if [ "${GO}" == "1" ]
then
    cd go/heat
    go build -ldflags "-s -w" main.go

    for i in {40..0..2}
    do 
        ./main $i ${TIME} ${SIZE}
    done

    cd ../..
fi


if [ "${CHAPEL}" == "1" ]
then
    cd chapel
    /work/diehlpk/Compile/all/chapel-1.29.0/bin/linux64-x86_64/chpl --fast heat.chpl 
    for i in {40..0..2}
    do 
        CHPL_RT_NUM_THREADS_PER_LOCALE=$i ./heat --nx ${SIZE} --nt ${TIME} >> perfstat.csv
    done

    cd ../
fi


if [ "${CXX}" == "1" ]
then
    cd cxx
    g++ -o heat -O3 -std=c++17 heat.cxx -pthread
    for i in {40..0..2}
    do 
        ./heat $i ${TIME} ${SIZE}  
    done

    cd ../
fi


if [ "${JULIA}" == "1" ]
then
    cd julia
    
    for i in {40..0..2}
    do 
        /work/diehlpk/Compile/all/julia-1.8.5/bin/julia -O3 --threads $i heat_ghost.jl  $i ${TIME} ${SIZE} > data.csv 
    done

    cd ../
fi


if [ "${CHARM}" == "1" ]
then
    cd charm

    $CHARM_DIR/charmc stencil_1d.ci
    $CHARM_DIR/charmc stencil_1d.cpp -c++-option -std=c++17 -lstdc++fs -o stencil_1d -O3 -march=native

    for i in {40..0..2}
    do 
    ./charmrun ./stencil_1d +p $i $((2*${i})) ${TIME} ${SIZE}
    done

    cd ../
fi


if [ "${HPX}" == "1" ]
then
    cd hpx/heat/bin
    for i in {40..0..2}
    do 
        ./heat_ghosts $i ${TIME} ${SIZE} --hpx:threads=$i 
    done

    cd ../../..
fi
