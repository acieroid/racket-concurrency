#!/bin/sh
# Use as follows for fact.rkt example, after creating threads/fact.abs with abstract results properly formatted:
# $ source run.sh
# $ run threads/fact

ITERATIONS=10

run() {
    echo === $1 ===
    echo > $1.conc
    for i in $(seq $ITERATIONS); do
        gecho -ne "Iteration $i/$ITERATIONS\r"
        racket $1.rkt | gawk '// { if (logging==1) { print $0 } } /RESULTS:/ { logging=1 }' >> $1.conc
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
