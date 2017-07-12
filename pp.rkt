#lang racket
(require "actors.rkt")
(letrec ((ping-actor
          (a/actor "ping" (count pong)
                 (start ()
                        (a/send pong send-ping a/self)
                        (a/become ping-actor (- count 1) pong))
                 (ping ()
                       (a/send pong send-ping a/self)
                       (a/become ping-actor (- count 1) pong))
                 (send-pong ()
                            (if (> count 0)
                                (begin
                                  (a/send a/self ping)
                                  (a/become ping-actor count pong))
                                (begin
                                  (a/send pong stop)
                                  (a/terminate))))))
         (pong-actor
          (a/actor "pong" (count)
                 (stop () (a/terminate))
                 (send-ping (to)
                            (a/send to send-pong)
                            (a/become  pong-actor (+ count 1)))))
         (pong (a/create pong-actor 0))
         (N (int-top))
         (ping (a/create ping-actor N pong)))
  (a/send ping start)
  (a/wait))