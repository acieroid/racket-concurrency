#!/bin/sh

ITERATIONS=100

run() {
    echo === $1 ===
    rm $1.conc
    for i in $(seq $ITERATIONS); do
        racket $1.rkt | gawk '// { if (logging==1) { print $0 } } /exiting/ { logging=1 }' >> $1.conc
        if [ $? == 130 ]; then
           exit
        fi
        racket compare.rkt $1.conc $1.abs | grep -v "result: #t"
        if [ $? == 130 ]; then
            exit
        fi
    done
}

run pp # good (0 overapproximations, no unsound)
run count # good (0 overapproximations, no unsound)
run fjt # good (0 overapproximations, no unsound)
run fjc # good (0 overapproximations, no unsound)
run thr # good (2 overapproximations every time)
run cham # good (5 overapproximations every time)
run big # good (2 overapproximations every time)

run cdict # good (1 overapproximation every time)
run csll # good (1 overapproximation every time)
