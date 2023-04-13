#!/usr/bin/bash

source "$HOME/.cargo/env"

module load python/3.10.5

PYTHON=1
SWIFT=1
RUST=1
GO=1

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

    for i in {40..0..2}
    do 
        ./main $i ${TIME} ${SIZE}
    done

    cd ../..
fi

