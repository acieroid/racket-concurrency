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

(define (fact-thread from to)
  (if (<= (- to from) FragmentSize)
      (product from to)
      (let ((steps (split from to)))
        (foldl * 1
               (map (lambda (t) (t/join t))
                    (map (lambda (bounds)
                           (t/spawn
                            (fact-thread (car bounds) (cdr bounds))))
                         steps))))))

(define (fact n)
  (let* ((t (t/spawn (fact-thread 1 n)))
         (res (t/join t)))
    (printf "fact(~a) = ~a~n" n res)))

(fact N)
(t/show-recorded)
