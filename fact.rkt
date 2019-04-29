#lang racket
(require "threads.rkt")

(define N (int-top))
(define FragmentSize 10)

(define (split from to)
  (let ((half (quotient (- to from) 2)))
    (list (cons from (+ from half))
          (cons (+ from half 1) to))))

(define (product from to)
  (if (= from to)
      from
      (* from (product (+ from 1) to))))

(define (fact-thread from to result result-lock)
  (printf "fact-thread ~a ~a~n" from to)
  (if (<= (- to from) FragmentSize)
      (let ((partial-fact (product from to)))
        (t/acquire result-lock)
        (t/ref-set result (* (t/deref result) partial-fact))
        (t/release result-lock))
      (let ((steps (split from to)))
        (map (lambda (t) (t/join t))
             (map (lambda (bounds)
                    (printf "creating fact(~a)~n" bounds)
                    (t/spawn
                     (fact-thread (car bounds) (cdr bounds)
                                  result result-lock)))
                  steps)))))

(define (fact n)
  (let* ((result (t/ref 1)) (result-lock (t/new-lock))
         (t (t/spawn (fact-thread 1 n result result-lock))))
    (t/join t)
    (printf "fact(~a) = ~a~n" n (t/deref result))))

(fact 15)
