#lang racket
(provide t/spawn)
(provide t/join)
(provide t/new-lock)
(provide t/acquire)
(provide t/release)
(provide t/ref)
(provide t/ref-set)
(provide t/deref)
(provide int-top)

(define (int-top) (+ 1 (random 20)))

(define thread-return-values (make-hash)) ;; map thread -> value
(define (thread-set-return-value t v)
  (hash-set! thread-return-values t v))
(define (thread-return-value t)
  (hash-ref thread-return-values t))

(define thread-names (make-hash)) ;; map thread -> name
(define (thread-set-name t v)
  (hash-set! thread-names t v))
(define (thread-name t)
  (hash-ref thread-names t))

(define (abstract x)
  (cond ((integer? x) '{Num})
        ((real? x) '{Num})
        ((string? x) '{Str})
        ((symbol? x) '{Sym})
        ((thread? x) (if (hash-has-key? thread-names x) (string->symbol (hash-ref thread-names x)) "???"))
        ((procedure? x) x)
        ((list? x) "\"#<list>\"")
        ((vector? x) "\"#<vector>\"")
        (else x)))

;; TODO: replace every t/t2 by its name, looking it up in tread-names
(define threads-created (make-hash)) ;; map name -> name
(define threads-created-sem (make-semaphore 1))
(define (thread-created t t2 exp)
  (semaphore-wait threads-created-sem)
  (if (not (hash-has-key? threads-created t))
      (hash-set! threads-created t (set (cons t2 exp)))
      (hash-set! threads-created t (set-add (hash-ref threads-created t) (cons t2 exp))))
  (semaphore-post threads-created-sem))

(define threads-joined (make-hash)) ;; map name -> name
(define threads-joined-sem (make-semaphore 1))
(define (thread-join t t2)
  (semaphore-wait threads-joined-sem)
  (if (not (hash-has-key? threads-joined t))
      (hash-set! threads-joined t (set t2))
      (hash-set! threads-joined t (set-add (hash-ref threads-joined t) t2)))
  (semaphore-post threads-joined-sem))

(define addresses-read (make-hash)) ;; map name -> addr
(define addresses-read-sem (make-semaphore 1))
(define (address-read t addr val)
  (semaphore-wait addresses-read-sem)
  (hash-set! addresses-read t (set-add
                               (if (hash-has-key? addresses-read t)
                                   (hash-ref addresses-read t)
                                   (set)) (cons addr (abstract val))))
  (semaphore-post addresses-read-sem))

(define addresses-written (make-hash)) ;; map name -> addr
(define addresses-written-sem (make-semaphore 1))
(define (address-written t addr val)
  (semaphore-wait addresses-written-sem)
  (hash-set! addresses-written t (set-add
                                  (if (hash-has-key? addresses-written t)
                                      (hash-ref addresses-written t)
                                      (set))
                                  (cons addr (abstract val))))
  (semaphore-post addresses-written-sem))

(define locks-acquired (make-hash)) ;; map name -> addr
(define locks-acquired-sem (make-semaphore 1))
(define (lock-acquired t addr)
  (semaphore-wait locks-acquired-sem)
  (hash-set! locks-acquired t (set-add
                               (if (hash-has-key? locks-acquired t)
                                   (hash-ref locks-acquired t)
                                   (set))
                               addr))
  (semaphore-post locks-acquired-sem))

(define locks-released (make-hash)) ;; map name -> addr
(define locks-released-sem (make-semaphore 1))
(define (lock-released t addr)
  (semaphore-wait locks-released-sem)
  (hash-set! locks-released t (set-add
                               (if (hash-has-key? locks-released t)
                                   (hash-ref locks-released t)
                                   (set)) addr))
  (semaphore-post locks-released-sem))

(define-syntax (t/spawn stx)
  (with-syntax [(exp (format "~a" stx))]
    (syntax-case stx ()
      [(t/spawn e)
       #'(letrec ((t (thread (lambda ()
                               (let ((v e))
                                 (thread-set-return-value t v))))))
           (thread-created (current-thread) t exp)
         t)])))
(define (t/join t)
  (thread-join (current-thread) t)
  (thread-wait t)
  (thread-return-value t))

(define-syntax-rule (log e ...)
  (begin
    (printf "executing ~a~n" (quote (begin e ...)))
    (let ((res (begin e ...)))
      (printf "done: ~a returns ~a~n" (quote (begin e ...)) res)
      res)))

(define-syntax (t/new-lock stx)
  (with-syntax [(addr (format "~a" stx))]
    (syntax-case stx ()
      [(t/new-lock) #'(cons (make-semaphore 1) addr)])))
(define (t/acquire lock)
  (lock-acquired (current-thread) (cdr lock))
  (semaphore-wait (car lock)))
(define (t/release lock)
  (lock-released (current-thread) (cdr lock))
  (semaphore-post (car lock)))

(define-syntax (t/ref stx)
  (with-syntax [(addr (format "~a" stx))]
    (syntax-case stx ()
      [(t/ref val) #'(mcons val addr)])))
(define (t/ref-set var val)
  (address-written (current-thread) (mcdr var) val)
  (set-mcar! var val))
(define (t/deref var)
  (let ((val (mcar var)))
    (address-read (current-thread) (mcar var) val)
    val))
(define (t/display-recorded)
  'todo)
