#lang racket
(provide bool-top)
(provide int-top)

(define (int-top)
  (let ((v (+ 1 (if (bool-top) (random 5) (random 6))))) (fprintf (current-error-port) "~n|generated: ~a|~n" v) v)
  )
(define (bool-top) (if (= (random 2) 1) #t #f))

