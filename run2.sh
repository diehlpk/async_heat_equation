#!/usr/bin/bash
#  Copyright (c) 2023 AUTHORS
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. (See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

if [ ! -r ~/.cargo/env ]
then
  curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y
fi
source ~/.cargo/env
set -e
make -f run2.mk

CHARM_RUN=/charm/multicore-linux-x86_64-gcc/bin/charmrun
source /root/.cargo/env

PYTHON=0
SWIFT=0
RUST=0
GO=0
CHAPEL=0
CHAPEL_NOGHOSTS=0
CXX=0
JULIA=1
CHARM=0
HPX=0
JAVA=0

TIME=1000
SIZE=1000000

CPUS=$(lscpu | grep 'CPU(s):' | cut -d: -f2 | sed 's/[ \t]//g')

echo 'lang,nx,nt,threads,dt,dx,total time,flops' > perfdata.csv

if [ "${PYTHON}" == "1" ]
then
    echo
    echo "RUNNING PYTHON"
    for i in $(seq 1 $CPUS)
    do 
        echo python3 python/heat/heat_ghosts.py $i ${TIME} ${SIZE} 0 
        python3 python/heat/heat_ghosts.py $i ${TIME} ${SIZE} 0 
    done

fi

if [ "${SWIFT}" == "1" ]
then
    echo
    echo "RUNNING SWIFT"
    for i in $(seq 3 $CPUS)
    do 
        echo ./swift/heat/heat_ghosts $i ${TIME} ${SIZE} 
        ./swift/heat/heat_ghosts $i ${TIME} ${SIZE} >> perfdata.csv
    done
fi


if [ "${RUST}" == "1" ]
then
    echo
    echo "RUNNING RUST"
    for i in $(seq 1 $CPUS)
    do 
        echo ./rust/heat/target/release/heat_ghosts $i ${TIME} ${SIZE}
        ./rust/heat/target/release/heat_ghosts $i ${TIME} ${SIZE}
    done
fi


if [ "${GO}" == "1" ]
then
    echo
    echo "RUNNING GO"
    for i in $(seq 1 $CPUS)
    do 
        echo ./go/heat/main $i ${TIME} ${SIZE}
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
        echo CHPL_RT_NUM_THREADS_PER_LOCALE=$i ./chapel/heat/heat_ghosts --nthreads $i --nx ${SIZE} --nt ${TIME}
        CHPL_RT_NUM_THREADS_PER_LOCALE=$i ./chapel/heat/heat_ghosts --nthreads $i --nx ${SIZE} --nt ${TIME} >> perfdata.csv
    done
fi


if [ "${CHAPEL_NOGHOSTS}" == "1" ]
then
    echo
    echo "RUNNING CHAPEL NOGHOSTS"
    for i in $(seq 1 $CPUS)
    do 
        echo CHPL_RT_NUM_THREADS_PER_LOCALE=$i ./chapel/heat/heat --nx ${SIZE} --nt ${TIME}
        CHPL_RT_NUM_THREADS_PER_LOCALE=$i ./chapel/heat/heat --nx ${SIZE} --nt ${TIME} >> perfdata.csv
    done
fi


if [ "${CXX}" == "1" ]
then
    echo
    echo "RUNNING C++"
    for i in $(seq 1 $CPUS)
    do 
        echo ./cxx/heat/heat_ghosts $i ${TIME} ${SIZE}  
        ./cxx/heat/heat_ghosts $i ${TIME} ${SIZE}  
    done
fi


if [ "${HPX}" == "1" ]
then
    echo
    echo "RUNNING HPX"
    for i in $(seq 1 $CPUS)
    do 
        echo ./hpx/heat/build/bin/heat_ghosts $i ${TIME} ${SIZE}  
        ./hpx/heat/build/bin/heat_ghosts $i ${TIME} ${SIZE}  
    done
fi


if [ "${JULIA}" == "1" ]
then
    echo
    echo "RUNNING JULIA"
    for i in $(seq 2 ${CPUS})
    do 
        echo julia -O3 --threads $i ./julia/heat/heat_ghosts.jl  $i ${TIME} ${SIZE} 
        julia -O3 --threads $i ./julia/heat/heat_ghosts.jl  $i ${TIME} ${SIZE} >> perfdata.csv 
    done
fi


if [ "${CHARM}" == "1" ]
then
    echo
    echo "RUNNING CHARM"

    for i in $(seq 1 $CPUS)
    do 
      echo '$CHARM_RUN' ./charm/heat/heat_ghosts +p $i $((2*${i})) ${TIME} ${SIZE}
      $CHARM_RUN ./charm/heat/heat_ghosts +p $i $((2*${i})) ${TIME} ${SIZE}
    done
fi

if [ "${JAVA}" == "1" ]
then
    echo
    echo "RUNNING JAVA"
    for i in $(seq 1 $CPUS)
    do 
        echo java -cp ./java/heat/classes edu.lsu.cct.heat.Main $i ${TIME} ${SIZE}
        java -cp ./java/heat/classes edu.lsu.cct.heat.Main $i ${TIME} ${SIZE}
    done
fi
