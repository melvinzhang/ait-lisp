#lang ait
;; ELEGANT S-EXPRESSIONS CANNOT BE PROVED ELEGANT
;; A #lang ait port of godel.l. Run with: racket -S src lm/godel.rkt
;;
;; An S-expression is elegant if no smaller S-expression has the same value.
;; A formal axiomatic system (FAS) is modelled as a LISP expression that
;; displays the S-expressions it proves elegant. Its LISP complexity N is
;; at most its size.
;;
;; Claim: a FAS of LISP complexity N cannot prove elegant any S-expression
;; of size greater than N + 410.
;;
;; Proof: the searcher below runs the FAS for longer and longer, waiting
;; for a theorem "s is elegant" with size(s) > n, and then evaluates s.
;; The searcher's own size is exactly n. So if it ever finds s, it has the
;; same value as s and is smaller than s: s is not elegant, and the FAS
;; proved something false.

(require racket/runtime-path racket/file racket/list)

;; --- The searcher ---

;; godel.l's key expression, with the FAS and the constant left as holes.
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

;; n must be the searcher's own size: the FAS's size plus everything else.
;; Everything else is the searcher's overhead, which includes the digits
;; of the constant itself. godel.l types 410; here it is derived.
(define searcher* (fix-overhead searcher))
(define c (overhead searcher*))
(expect c ⇒ 410)

(define (expression fas) (plug searcher* #:fas fas))

;; The size of the expression is N + c for every FAS: c doesn't depend on it.
(define (toy-fas k) @lisp{display ^ 10 @k}) ; "10^k is elegant"
(define fases
  (list (toy-fas 430)
        (toy-fas 5)
        @lisp{cons display 'x cons display '(a b) display ^ 10 500}
        @lisp{let (f x) if = x 0 nil cons display x (f - x 1) (f 10)}))
(property "size(expression) = size(FAS) + c" ([fas fases])
  (= (size (expression fas)) (+ (size fas) c)))

;; Both expressions in godel.l are the searcher with toy-fas plugged in.
(define-runtime-path godel.l "godel.l")
(define godel-forms (lisp* (file->string godel.l)))
(expect (expression (toy-fas 430)) ⇒ (caddr (first godel-forms)))
(expect (expression (toy-fas 429)) ⇒ (fourth godel-forms))
(expect (size (expression (toy-fas 430))) ⇒ 430) ; as godel.r shows

;; --- Running it ---

;; toy-fas k "proves" that 10^k, which has k+1 digits, is elegant.
;; godel.l runs k = 430 and k = 429 as two copies of the whole expression.
(threshold (expression (toy-fas k))
  #:vary k #:over '(427 428 429 430 431 432)
  #:observe (λ (o) (if (number? (outcome-value o)) 'refutes-the-fas 'finds-nothing))
  #:flips-at 430
  #:explain "With N = 20, the searcher's size is 430. It finds a theorem
   big enough to refute as soon as 10^k has more than 430 digits.")

;; At k = 430 the FAS claims s = 10^430 is elegant. The searcher
;; computes the same value as s while being smaller than s.
(define fas (toy-fas 430))
(define s
  (for/first ([x (outcome-displays (run fas))]
              #:when (> (size x) (+ c (size fas))))
    x))
(expect (size s) ⇒ 431)
(bound (size (expression fas)) < (size s))
(expect (value (expression fas)) ⇒ (value s))

;; The theorem itself: whenever the searcher evaluates an s, s is larger
;; than N + c, so a FAS of complexity N proves nothing that big elegant.
(property "every s the searcher evaluates has size > size(FAS) + c"
  ([fas fases])
  (define found
    (for/first ([x (outcome-displays (run fas))]
                #:when (> (size x) (+ c (size fas))))
      x))
  (define v (outcome-value (run (expression fas))))
  (if found
      (and (> (size found) (+ (size fas) c)) (equal? v (value found)))
      (eq? v 'failure)))
