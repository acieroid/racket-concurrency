#!/bin/sh

ITERATIONS=10

run() {
    echo === $1 ===
    echo > $1.conc
    for i in $(seq $ITERATIONS); do
        gecho -ne "Iteration $i/$ITERATIONS\r"
        racket $1.rkt | gawk '// { if (logging==1) { print $0 } } /exiting/ { logging=1 }' >> $1.conc
        if [ $? == 130 ]; then
           exit
        fi
    done
    echo "Modular Analysis:"
    racket compare.rkt $1.conc $1.abs
    if [ $? == 130 ]; then
        exit
    fi
    echo "========"
    if [ -f "$1.abs.nonmod" ]; then
        echo "Non-modular analysis:"
        racket compare.rkt $1.conc $1.abs.nonmod
        if [ $? == 130 ]; then
            exit
        fi
    fi
}

# run pp # 0
#run count # 0
#run fjt # 0
#run fjc # 0
#run thr # 2
#run cham # 5
#run big # 2

# run cdict # 1
# run csll # 1
# run pcbb # TODO
# run phil # 0
# run sbar # 0
# run cig # 1
# run logm # TODO: implement
# run btx # 1

# run rsort
# run fbank
# run sieve
# run uct
# run ofl
# run trapr
# run piprec
# run rmm
# run qsort
# run apsp
# run sor
# run astar
# run nqn
