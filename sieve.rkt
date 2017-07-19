#lang racket
(require "actors.rkt")
(define Limit (+ 100 (int-top)))
(define NumMaxLocalPrimes (+ 20 (int-top)))

(define (locally-prime n) (bool-top)) ;; not modeled
(define number-producer-actor
  (a/actor "number-producer-actor" ()
           (prime-filter (actor)
                         (letrec ((loop (lambda (candidate)
                                          (if (>= candidate Limit)
                                              (begin
                                                (a/send actor exit)
                                                (a/terminate))
                                              (begin
                                                (a/send actor candidate candidate)
                                                (loop (+ candidate 2)))))))
                           (loop 3)))))
(define prime-filter-actor
  (a/actor "prime-filter-actor" (id initial next local-primes available-local-primes)
           (candidate (candidate)
                      (if (locally-prime candidate)
                          (begin
                            (a/log "locally-prime, next is ~a~n" next)
                            (if next
                                (begin
                                  (a/send next candidate candidate)
                                  (a/become prime-filter-actor id initial next local-primes available-local-primes))
                                (begin
                                  (a/log "available: ~a, max: ~a, create if >=~n" available-local-primes NumMaxLocalPrimes)
                                  (if (< available-local-primes NumMaxLocalPrimes)
                                      (a/become prime-filter-actor id initial next (cons candidate local-primes) (+ available-local-primes 1))
                                      (let ((new-next (a/create prime-filter-actor (+ id 1) candidate #f (cons candidate '()) 1)))
                                        (a/become prime-filter-actor id initial new-next local-primes available-local-primes))))))
                          (a/become prime-filter-actor id initial next local-primes available-local-primes)))
           (exit ()
                 (if next
                     (a/send next exit)
                     #t)
                 (a/terminate))))

(define producer (a/create number-producer-actor))
(define filter (a/create prime-filter-actor 1 2 #f (cons 2 '()) 1))
(a/send producer prime-filter filter)
(a/wait)
