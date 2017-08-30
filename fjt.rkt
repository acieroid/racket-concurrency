#lang racket
(require "actors.rkt")
(define N (int-top))
(define A (int-top))

(define (build-vector n f)
  (letrec ((v (make-vector n #f))
           (loop (lambda (i)
                   (if (< i n)
                       (begin
                         (vector-set! v i (f i))
                         (loop (+ i 1)))
                       v))))
    (loop 0)))

(define (vector-foreach f v)
  (letrec ((loop (lambda (i)
                   (if (< i (vector-length v))
                       (begin
                         (f (vector-ref v i))
                         (loop (+ i 1)))
                       'done))))
    (loop 0)))

(define (perform-computation theta)
  (let ((sint (+ 1 theta)))
    (* sint sint)))

(define throughput-actor
  (a/actor "throughput" (processed)
           (message ()
                    (perform-computation 37.2)
                    (if (= (+ processed 1) N)
                        (a/terminate)
                        (a/become throughput-actor (+ processed 1))))))

(define actors (build-vector A (lambda (i) (a/create throughput-actor 0))))

(define loop (lambda (n)
               (if (= n N)
                   'done
                   (begin
                     (vector-foreach (lambda (a) (a/send a message)) actors)
                     (loop (+ n 1))))))
(loop 0)
(a/wait)
