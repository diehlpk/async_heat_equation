#!/usr/bin/bash
if [ ! -r ~/.cargo/env ]
then
  curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y
fi
source ~/.cargo/env
make -f run2.mk

CHARM_DIR=/work/diehlpk/Compile/medusa/charm/bin/
source /root/.cargo/env

PYTHON=1
SWIFT=0
RUST=1
GO=1
CHAPEL=1
CXX=1
JULIA=1
CHARM=0

TIME=1000
SIZE=100000

CPUS=$(lscpu | grep 'CPU(s):' | cut -d: -f2 | sed 's/[ \t]//g')

echo 'lang,nx,nt,threads,dt,dx,total time,flops' > perfdata.csv

if [ "${PYTHON}" == "1" ]
then
    echo
    echo "RUNNING PYTHON"
    for i in $(seq 1 $CPUS)
    do 
        python3 python/heat2.py $i ${TIME} ${SIZE} 0 
    done

fi

if [ "${SWIFT}" == "1" ]
then
    cd swift/heat

    for i in $(seq 1 $CPUS)
    do 
        ./heat_3 $i ${TIME} ${SIZE} >> perfstat.csv
    done

    cd ../..
fi


if [ "${RUST}" == "1" ]
then
    echo
    echo "RUNNING RUST"
    for i in $(seq 1 $CPUS)
    do 
        ./rust/heat/target/release/heat $i ${TIME} ${SIZE}
    done
fi


if [ "${GO}" == "1" ]
then
    echo
    echo "RUNNING GO"
    for i in $(seq 1 $CPUS)
    do 
        ./go/heat/main $i ${TIME} ${SIZE}
    done
fi


if [ "${CHAPEL}" == "1" ]
then
    echo
    echo "RUNNING CHAPEL"
    # Deadlocks for 1
    for i in $(seq 2 $CPUS)
    do 
        CHPL_RT_NUM_THREADS_PER_LOCALE=$i ./chapel/heat_ghost --nx ${SIZE} --nt ${TIME} >> perfdata.csv
    done
fi


if [ "${CXX}" == "1" ]
then
    echo
    echo "RUNNING C++"
    for i in $(seq 1 $CPUS)
    do 
        ./cxx/heat $i ${TIME} ${SIZE}  
    done
fi


if [ "${JULIA}" == "1" ]
then
    echo
    echo "RUNNING JULIA"
    for i in $(seq 2 ${CPUS})
    do 
        julia -O3 --threads $i ./julia/heat_ghost.jl  $i ${TIME} ${SIZE} >> perfdata.csv 
    done
fi


if [ "${CHARM}" == "1" ]
then
    cd charm

    $CHARM_DIR/charmc stencil_1d.ci
    $CHARM_DIR/charmc stencil_1d.cpp -c++-option -std=c++17 -lstdc++fs -o stencil_1d -O3 -march=native

    for i in {${CPUS}..0..2}
    do 
    ./charmrun ./stencil_1d +p $i $((2*${i})) ${TIME} ${SIZE}
    done

    cd ../
fi


