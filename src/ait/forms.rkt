#lang racket/base
;; Meta-level forms of #lang ait.
;;
;; Object code is Chaitin LISP held as Racket data: exact integers,
;; symbols and lists. Nothing here changes an object expression except
;; plug and fix-overhead, which only fill holes, so sizes stay honest.
;;
;; A hole is an atom written {name} in object code.

(require (for-syntax racket/base syntax/parse)
         racket/list
         racket/string
         "machine.rkt")

(provide lisp lisp*
         show abbrev size bits
         run value run-utm
         (struct-out outcome)
         holes plug overhead fix-overhead
         expect bound threshold ⇒
         report-summary!)

;; --- Object code ---

;; @lisp{...} parses M-expression text into one S-expression.
;; Non-string pieces (@expr inside the braces) are spliced in as data.
(define (lisp . pieces)
  (define es (apply lisp* pieces))
  (unless (= 1 (length es))
    (error 'lisp "expected exactly one expression, got ~a in: ~a"
           (length es) (string-append* (map piece->text pieces))))
  (car es))

;; @lisp*{...} parses M-expression text into a list of S-expressions.
(define (lisp* . pieces)
  (define splices
    (for/list ([p (in-list pieces)] #:unless (string? p)) p))
  (define names
    (for/list ([i (in-range (length splices))])
      (string->symbol (format "@splice~a@" i))))
  (define text
    (let loop ([ps pieces] [ns names])
      (cond
        [(null? ps) ""]
        [(string? (car ps)) (string-append (car ps) (loop (cdr ps) ns))]
        [else (string-append " " (symbol->string (car ns)) " "
                             (loop (cdr ps) (cdr ns)))])))
  (define table (map cons names splices))
  (for/list ([e (in-list (lisp-parse text))])
    (substitute e (λ (s) (assq s table)))))

(define (piece->text p) (if (string? p) p (show p)))

(define (substitute e lookup)
  (cond
    [(symbol? e) (let ([hit (lookup e)]) (if hit (cdr hit) e))]
    [(pair? e) (map (λ (x) (substitute x lookup)) e)]
    [else e]))

;; Prints an S-expression as the machine does; size is its length.
(define (show e)
  (cond
    [(null? e) "()"]
    [(symbol? e) (symbol->string e)]
    [(exact-nonnegative-integer? e) (number->string e)]
    [(list? e) (string-append "(" (string-join (map show e) " ") ")")]
    [else (format "~v" e)]))

(define (abbrev e [width 60])
  (define s (show e))
  (if (<= (string-length s) width)
      s
      (format "~a… [~a chars]" (substring s 0 (- width 12)) (string-length s))))

(define (size e) (string-length (show e)))

;; Eight bits per character, MSB first, then a newline, as `bits` does.
(define (bits e)
  (for*/list ([c (in-string (string-append (show e) "\n"))]
              [i (in-range 7 -1 -1)])
    (if (bitwise-bit-set? (char->integer c) i) 1 0)))

;; --- Running ---

(define (run e #:time [time #f] #:tape [tape '()] #:defs [defs '()])
  (lisp-run e #:time time #:tape tape #:defs defs))

(define (value e #:time [time #f] #:tape [tape '()] #:defs [defs '()])
  (define o (run e #:time time #:tape tape #:defs defs))
  (unless (eq? 'success (outcome-status o))
    (error 'value "~a failed: ~a" (abbrev e) (outcome-value o)))
  (outcome-value o))

;; Runs a self-delimiting program on the universal machine U:
;; U reads an S-expression from the tape and evaluates it.
(define (run-utm tape #:time [time #f])
  (run '(eval (read-exp)) #:time time #:tape tape))

;; --- Contexts: object code with holes ---

(define (hole-name s)
  (define m (regexp-match #rx"^{(.+)}$" (symbol->string s)))
  (and m (string->symbol (cadr m))))

(define (hole-occurrences e)
  (cond
    [(symbol? e) (if (hole-name e) (list e) '())]
    [(pair? e) (append-map hole-occurrences e)]
    [else '()]))

(define (holes e) (remove-duplicates (map hole-name (hole-occurrences e))))

;; (plug K #:fas e ...) fills holes; unfilled holes stay.
(define plug
  (make-keyword-procedure
   (λ (kws vals k)
     (define names (map (λ (kw) (string->symbol (keyword->string kw))) kws))
     (for ([n (in-list names)])
       (unless (memq n (holes k))
         (error 'plug "no hole {~a} in: ~a" n (abbrev k))))
     (define table (map cons names vals))
     (substitute k (λ (s) (let ([n (hole-name s)]) (and n (assq n table))))))))

;; The size of everything except the holes. Filling every hole adds
;; exactly the sizes of the fillers, since size is printed length.
(define (overhead k)
  (- (size k) (for/sum ([h (in-list (hole-occurrences k))]) (size h))))

;; Fills {hole} with the constant c that bounds the result's own overhead,
;; i.e. the least c found with c >= (overhead result). The constant's
;; digits count towards the overhead it is measuring.
(define (fix-overhead k #:hole [hole 'overhead])
  (unless (memq hole (holes k))
    (error 'fix-overhead "no hole {~a} in: ~a" hole (abbrev k)))
  (define (fill c) (plug-one k hole c))
  (let loop ([c 0])
    (define o (overhead (fill c)))
    (if (>= c o) (fill c) (loop o))))

(define (plug-one k hole v)
  (substitute k (λ (s) (and (eq? (hole-name s) hole) (cons s v)))))

;; --- Checks ---

(define results '())

(define (record! ok? where msg)
  (set! results (cons ok? results))
  (printf "~a ~a  ~a\n" (if ok? "✓" "✗") where msg))

(define (report-summary!)
  (define failed (count not results))
  (printf "\n~a checks, ~a failed\n" (length results) failed)
  (unless (zero? failed) (exit 1)))

(define (fmt v)
  (if (or (null? v) (symbol? v) (exact-nonnegative-integer? v)
          (and (list? v) (andmap (λ (x) (or (symbol? x) (number? x) (list? x))) v)))
      (abbrev v)
      (format "~v" v)))

(define-syntax ⇒
  (λ (stx) (raise-syntax-error #f "only allowed inside expect" stx)))

(begin-for-syntax
  (define (where stx)
    (define src (syntax-source stx))
    (format "~a:~a"
            (if (path? src)
                (let-values ([(_ name __) (split-path src)]) (path->string name))
                "?")
            (or (syntax-line stx) "?"))))

;; (expect actual ⇒ expected): actual must be equal? to expected.
(define-syntax (expect stx)
  (syntax-parse stx
    #:literals (⇒ =>)
    [(_ actual (~or ⇒ =>) expected)
     #`(do-expect 'actual (λ () actual) expected #,(where stx))]))

(define (do-expect form thunk expected where)
  (with-handlers ([exn:fail? (λ (e) (record! #f where (format "~s raised: ~a"
                                                              form (exn-message e))))])
    (define actual (thunk))
    (if (equal? actual expected)
        (record! #t where (format "~s ⇒ ~a" form (fmt actual)))
        (record! #f where (format "~s ⇒ ~a, expected ~a"
                                  form (fmt actual) (fmt expected))))))

;; (bound lhs op rhs): a numeric inequality, reported with its values.
(define-syntax (bound stx)
  (syntax-parse stx
    [(_ lhs op:id rhs)
     #`(do-bound 'lhs (λ () lhs) 'op op 'rhs (λ () rhs) #,(where stx))]))

(define (do-bound lform lthunk opname op rform rthunk where)
  (with-handlers ([exn:fail? (λ (e) (record! #f where (format "~s ~a ~s raised: ~a"
                                                              lform opname rform
                                                              (exn-message e))))])
    (define l (lthunk))
    (define r (rthunk))
    (record! (and (op l r) #t) where
             (format "~s = ~a ~a ~s = ~a" lform l opname rform r))))

;; (threshold program #:vary k #:over ks): runs program for each k and
;; tabulates what it does, e.g. where an incompleteness argument starts
;; to bite. With #:flips-at n, checks that the observation is the same
;; for every k < n, the same for every k >= n, and differs between them.
(define-syntax (threshold stx)
  (syntax-parse stx
    [(_ program:expr
        (~alt (~once (~seq #:vary k:id))
              (~once (~seq #:over ks:expr))
              (~optional (~seq #:observe observe:expr)
                         #:defaults ([observe #'default-observe]))
              (~optional (~seq #:time time:expr) #:defaults ([time #'#f]))
              (~optional (~seq #:flips-at n:expr) #:defaults ([n #'#f]))
              (~optional (~seq #:explain explain:expr)
                         #:defaults ([explain #'#f])))
        ...)
     #`(do-threshold 'k (λ (k) program) ks observe time n explain #,(where stx))]))

(define (default-observe o)
  (if (eq? 'success (outcome-status o))
      (outcome-value o)
      (list 'failure (outcome-value o))))

(define (do-threshold kname make ks observe time flip explain where)
  (printf "\n~a  threshold over ~a ∈ ~a\n" where kname (show ks))
  (when explain (printf "   ~a\n" explain))
  (define rows
    (for/list ([k (in-list ks)])
      (define p (make k))
      (define obs (observe (run p #:time time)))
      (printf "   ~a = ~a   size ~a   ⇒ ~a\n" kname k (size p) (fmt obs))
      (cons k obs)))
  (when flip
    (define-values (below above) (partition (λ (r) (< (car r) flip)) rows))
    (define (same? rs) (or (null? rs) (andmap (λ (r) (equal? (cdr r) (cdar rs))) rs)))
    (record! (and (pair? below) (pair? above) (same? below) (same? above)
                  (not (equal? (cdar below) (cdar above))))
             where
             (format "behaviour flips at ~a = ~a" kname flip))))
