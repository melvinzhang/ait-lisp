#lang ait
;; Tests for the meta forms. Run with: racket -S src src/ait/tests/meta.rkt

;; --- Object code and measurement ---

(define abc @lisp{'(a b c)})
(expect abc ⇒ '(|'| (a b c)))
(expect (show (cadr abc)) ⇒ "(a b c)")
(expect (lisp* "define x 1 [comment [nested]] car '(a)")
        ⇒ '((define x 1) (car (|'| (a)))))

;; size and bits agree with the machine's own primitives
(define sample (lisp "(f '(12 ab ()) nil 0 (()))"))
(expect (value (list 'size (list '|'| sample))) ⇒ (size sample))
(expect (value (list 'bits (list '|'| sample))) ⇒ (bits sample))
(expect (length (bits sample)) ⇒ (* 8 (add1 (size sample))))

;; splicing Racket data into object code
(define n 7)
(expect (value @lisp{+ @n 1}) ⇒ 8)
(expect (value @lisp{car '@abc}) ⇒ '|'|)

;; --- Running ---

(expect (value @lisp{let (f x) if atom x x (f car x) (f '(((a)) b))}) ⇒ 'a)
(expect (outcome-displays (run @lisp{cons display 1 display 2})) ⇒ '(1 2))
;; Inside parentheses primitives still take their arity: ('lambda (f) (f f) ...)
(expect (outcome-value (run @lisp{('lambda (f) (f f) 'lambda (f) (f f))} #:time 50))
        ⇒ 'out-of-time)
(expect (value @lisp{cons read-bit cons read-bit nil} #:tape '(1 0)) ⇒ '(1 0))
(expect (outcome-value (run @lisp{read-bit})) ⇒ 'out-of-data)
(expect (value @lisp{(f 5)} #:defs (lisp* "define (f x) * x x")) ⇒ 25)
(expect (value '(eval (read-exp)) #:tape (bits @lisp{+ 2 3})) ⇒ 5)
(expect (outcome-value (run-utm (bits @lisp{+ 2 3}))) ⇒ 5)

;; --- Contexts, using lm/godel.l as ground truth ---

;; The searcher from lm/godel.l, with the FAS and the constant as holes.
(define searcher
  @lisp{
    let (examine x)
        if atom x  false
        if < n size car x  car x
        (examine cdr x)
    let fas '{fas}
    let n + {overhead} size fas
    let t 0
    let (loop)
      let v try t fas nil
      let s (examine caddr v)
      if s eval s
      if = success car v failure
      let t + t 1
      (loop)
    (loop)
  })

;; Holes are listed in printed order; a let's body prints before its value.
(expect (holes searcher) ⇒ '(overhead fas))

;; The constant 410 in lm/godel.l is exactly the searcher's own overhead.
(define searcher* (fix-overhead searcher))
(expect (overhead searcher*) ⇒ 410)
(expect (holes searcher*) ⇒ '(fas))

(define (toy-fas k) @lisp{display ^ 10 @k})
(define (expression k) (plug searcher* #:fas (toy-fas k)))

;; Same expression as lm/godel.l, and the size lm/godel.r reports.
(require racket/runtime-path racket/file)
(define-runtime-path godel.l "../../../lm/godel.l")
(expect (expression 430) ⇒ (caddr (car (lisp* (file->string godel.l)))))
(expect (size (expression 430)) ⇒ 430)
(bound (size (expression 430)) <= (+ (overhead searcher*) (size (toy-fas 430))))

(threshold (expression k)
  #:vary k #:over '(428 429 430 431)
  #:observe (λ (o) (if (number? (outcome-value o)) 'exhibits-bigger 'finds-nothing))
  #:flips-at 430
  #:explain "The FAS displays 10^k, which has k+1 digits. Once that exceeds the
   searcher's own size, the searcher finds it and evaluates it.")

;; --- Failures are reported, not raised ---

(module+ test
  (require rackunit)
  (check-exn exn:fail? (λ () (lisp "car")))
  (check-exn exn:fail? (λ () (plug searcher #:nope 1)))
  (check-exn exn:fail? (λ () (value @lisp{read-bit}))))
