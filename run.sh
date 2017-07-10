#!/bin/sh

ITERATIONS=5

run() {
    echo === $1 ===
    for i in $(seq 5); do
        racket $1.rkt | gawk '// { if (logging==1) { print $0 } } /exiting/ { logging=1 }' > $1.conc
        if [ $? == 130 ]; then
           exit
        fi
        racket compare.rkt $1.conc $1.abs | grep -v "result: #t"
        if [ $? == 130 ]; then
            exit
        fi
    done
}

run pp
run count
run fjt
run fjc
run thr
run cham
run big
