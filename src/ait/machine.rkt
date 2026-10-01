#lang racket/base
;; Faithful port of src/lisp.go: Chaitin's AIT LISP as a node machine.
;;
;; The transcript format, the "Calls to eval/cons" counters and the
;; "Storage overflow!" limit are all observable in the reference .r files,
;; so this mirrors lisp.go allocation-for-allocation: every node lisp.go
;; allocates is allocated here too, in the same order.
;;
;; Values are node indices (fixnums). Node 0 is the atom "()" (nil).
;; A negative value -a signals an error whose reason is the atom a
;; (out-of-time or out-of-data). Name lists and internal bookkeeping
;; lists hold raw character codes / flags in their car, as in lisp.go.
;;
;; The machine is a single module-level instance; run-machine resets it.
;; The API at the end (lisp-parse, lisp-run) runs a fresh machine per call
;; and exchanges Racket data with it: exact integers for numbers, symbols
;; for atoms, and lists for lists.

(require racket/fixnum)

(provide run-machine
         lisp-parse
         lisp-run
         (struct-out outcome))

;; --- Constants ---

(define SIZE 1000000)
(define NIL 0)

(define KIND-CONS 0)
(define KIND-NUMBER 1)
(define KIND-ATOM 2)

(define PRIM-NONE 0)
(define PRIM-CAR 1)
(define PRIM-CDR 2)
(define PRIM-CONS 3)
(define PRIM-ATOM 4)
(define PRIM-EQ 5)
(define PRIM-DISPLAY 6)
(define PRIM-DEBUG 7)
(define PRIM-APPEND 8)
(define PRIM-LENGTH 9)
(define PRIM-LT 10)
(define PRIM-GT 11)
(define PRIM-LEQ 12)
(define PRIM-GEQ 13)
(define PRIM-PLUS 14)
(define PRIM-TIMES 15)
(define PRIM-POW 16)
(define PRIM-MINUS 17)
(define PRIM-2TO10 18)
(define PRIM-10TO2 19)
(define PRIM-SIZE 20)
(define PRIM-READ-BIT 21)
(define PRIM-BITS 22)
(define PRIM-READ-EXP 23)

;; --- Machine state ---

(define kinds (make-bytes SIZE KIND-CONS))
(define cars (make-fxvector SIZE 0))
(define cdrs (make-fxvector SIZE 0))
(define nums (make-vector SIZE 0))
(define names (make-fxvector SIZE 0))
(define stacks (make-fxvector SIZE 0))
(define codes (make-fxvector SIZE 0))
(define arities (make-fxvector SIZE 0))

(define object-list NIL)
(define next-free 0)
(define col 0)
(define time-eval 0)
(define tapes NIL)
(define display-enabled NIL)
(define captured-displays NIL)
(define q NIL)
(define buffer2 NIL)
(define in-word-buffer NIL)

(define in (current-input-port))
(define out (current-output-port))
;; How the machine stops; transcript mode follows lisp.go, API mode raises.
(define halt void) ; escape continuation; replaces os.Exit in lisp.go
(define on-overflow void)
(define on-eof void)
(define echo? #t)
(define debugs #f) ; list of debugged nodes when captured, else #f

(define sym-nil 0) (define sym-true 0) (define sym-false 0)
(define sym-define 0) (define sym-let 0) (define sym-lambda 0)
(define sym-quote 0) (define sym-if 0) (define sym-car 0) (define sym-cdr 0)
(define sym-cadr 0) (define sym-caddr 0) (define sym-eval 0) (define sym-try 0)
(define sym-no-time-limit 0) (define sym-out-of-time 0)
(define sym-out-of-data 0) (define sym-success 0) (define sym-failure 0)
(define left-bracket 0) (define right-bracket 0)
(define left-paren 0) (define right-paren 0) (define double-quote 0)
(define sym-zero 0) (define sym-one 0)
(define sym-read-exp 0) (define sym-utm 0)

;; --- Initialization & allocation ---

(define (init!)
  (unless (= NIL (mk-atom! PRIM-NONE "()" 0))
    (write-string "nil != 0\n" out)
    (halt))
  (define-syntax-rule (atoms! [name code args target] ...)
    (begin (let ([a (mk-atom! code name args)])
             (set! target a))
           ...))
  (define ignore 0)
  (atoms! ["nil" PRIM-NONE 0 sym-nil]
          ["true" PRIM-NONE 0 sym-true]
          ["false" PRIM-NONE 0 sym-false]
          ["no-time-limit" PRIM-NONE 0 sym-no-time-limit]
          ["out-of-time" PRIM-NONE 0 sym-out-of-time]
          ["out-of-data" PRIM-NONE 0 sym-out-of-data]
          ["success" PRIM-NONE 0 sym-success]
          ["failure" PRIM-NONE 0 sym-failure]
          ["define" PRIM-NONE 3 sym-define]
          ["let" PRIM-NONE 4 sym-let]
          ["lambda" PRIM-NONE 3 sym-lambda]
          ["cadr" PRIM-NONE 2 sym-cadr]
          ["caddr" PRIM-NONE 2 sym-caddr]
          ["run-utm-on" PRIM-NONE 2 sym-utm]
          ["'" PRIM-NONE 2 sym-quote]
          ["if" PRIM-NONE 4 sym-if]
          ["car" PRIM-CAR 2 sym-car]
          ["cdr" PRIM-CDR 2 sym-cdr]
          ["cons" PRIM-CONS 3 ignore]
          ["atom" PRIM-ATOM 2 ignore]
          ["=" PRIM-EQ 3 ignore]
          ["display" PRIM-DISPLAY 2 ignore]
          ["debug" PRIM-DEBUG 2 ignore]
          ["append" PRIM-APPEND 3 ignore]
          ["length" PRIM-LENGTH 2 ignore]
          ["<" PRIM-LT 3 ignore]
          [">" PRIM-GT 3 ignore]
          ["<=" PRIM-LEQ 3 ignore]
          [">=" PRIM-GEQ 3 ignore]
          ["+" PRIM-PLUS 3 ignore]
          ["*" PRIM-TIMES 3 ignore]
          ["^" PRIM-POW 3 ignore]
          ["-" PRIM-MINUS 3 ignore]
          ["base2-to-10" PRIM-2TO10 2 ignore]
          ["base10-to-2" PRIM-10TO2 2 ignore]
          ["size" PRIM-SIZE 2 ignore]
          ["read-bit" PRIM-READ-BIT 1 ignore]
          ["bits" PRIM-BITS 2 ignore]
          ["read-exp" PRIM-READ-EXP 1 sym-read-exp]
          ["eval" PRIM-NONE 2 sym-eval]
          ["try" PRIM-NONE 4 sym-try]
          ["[" PRIM-NONE 0 left-bracket]
          ["]" PRIM-NONE 0 right-bracket]
          ["(" PRIM-NONE 0 left-paren]
          [")" PRIM-NONE 0 right-paren]
          ["\"" PRIM-NONE 0 double-quote])
  (set-car! (stack sym-nil) NIL)
  (set! sym-zero (mk-num! 0))
  (set! sym-one (mk-num! 1)))

(define (alloc!)
  (when (>= next-free SIZE)
    (on-overflow))
  (define a next-free)
  (set! next-free (add1 next-free))
  a)

(define (mk-atom! code name args)
  (define a (alloc!))
  (define name-list (mk-string! name))
  (bytes-set! kinds a KIND-ATOM)
  (fxvector-set! names a name-list)
  (fxvector-set! codes a code)
  (fxvector-set! arities a args)
  (fxvector-set! stacks a NIL)
  (push-value! a a)
  (set! object-list (kons a object-list))
  a)

(define (push-value! a v) (set-stack! a (kons v (stack a))))

(define (pop-value! a)
  (define s (stack a))
  (unless (= s NIL) (set-stack! a (cdr* s))))

(define (peek-value a)
  (define s (stack a))
  (if (= s NIL) a (car* s)))

(define (mk-num! n)
  (define a (alloc!))
  (bytes-set! kinds a KIND-NUMBER)
  (vector-set! nums a n)
  a)

(define (to-int x)
  (if (and (not (= x NIL)) (= (bytes-ref kinds x) KIND-NUMBER))
      (vector-ref nums x)
      0))

;; Names are stored reversed, one character code per cons.
(define (mk-string! s)
  (for/fold ([v NIL]) ([c (in-string s)])
    (kons (char->integer c) v)))

(define (kons x y)
  (cond
    [(and (not (= y NIL)) (atom? y)) x] ; no dotted pairs
    [else
     (define z (alloc!))
     (bytes-set! kinds z KIND-CONS)
     (fxvector-set! cars z x)
     (fxvector-set! cdrs z y)
     z]))

(define (lst . xs)
  (let loop ([xs xs])
    (if (null? xs) NIL (let ([rest (loop (cdr xs))]) (kons (car xs) rest)))))

(define (bool->sym b) (if b sym-true sym-false))

;; --- Accessors ---

(define (cons? x) (= (bytes-ref kinds x) KIND-CONS))
(define (atom? x) (not (cons? x)))
(define (number? x) (= (bytes-ref kinds x) KIND-NUMBER))
(define (atom-kind? x) (= (bytes-ref kinds x) KIND-ATOM))

(define (car* x) (if (cons? x) (fxvector-ref cars x) x))
(define (cdr* x) (if (cons? x) (fxvector-ref cdrs x) x))
(define (set-car! x y) (when (cons? x) (fxvector-set! cars x y)))
(define (set-cdr! x y) (when (cons? x) (fxvector-set! cdrs x y)))
(define (stack x) (if (atom-kind? x) (fxvector-ref stacks x) NIL))
(define (set-stack! x y) (when (atom-kind? x) (fxvector-set! stacks x y)))
(define (name x) (if (atom-kind? x) (fxvector-ref names x) NIL))
(define (set-name! x y) (when (atom-kind? x) (fxvector-set! names x y)))
(define (prim-code x) (if (atom-kind? x) (fxvector-ref codes x) PRIM-NONE))
(define (prim-args x) (if (atom-kind? x) (fxvector-ref arities x) 0))

;; --- Output ---

(define (put-char c) (write-char (integer->char c) out))

(define (print! label x)
  (write-string label out)
  (write-string (make-string (max 0 (- 12 (string-length label))) #\space) out)
  (set! col 0)
  (serialize x print-char!)
  (newline out)
  x)

(define (serialize x emit)
  (cond
    [(number? x)
     (for ([c (in-string (number->string (to-int x)))])
       (emit (char->integer c)))]
    [(atom? x) (serialize-name (name x) emit)]
    [else
     (emit (char->integer #\())
     (let loop ([x x])
       (unless (atom? x)
         (serialize (car* x) emit)
         (let ([x (cdr* x)])
           (unless (atom? x) (emit (char->integer #\space)))
           (loop x))))
     (emit (char->integer #\)))]))

(define (serialize-name x emit)
  (unless (= x NIL)
    (serialize-name (cdr* x) emit)
    (emit (car* x))))

(define (print-char! c)
  (cond
    [(= col 50)
     (write-string "\n            " out)
     (set! col 1)]
    [else (set! col (add1 col))])
  (put-char c))

;; --- Utils ---

(define (binary-op x y op) (mk-num! (op (to-int (to-num x)) (to-int (to-num y)))))

(define (eq-word? x y)
  (cond
    [(= x NIL) (= y NIL)]
    [(= y NIL) #f]
    [(not (= (car* x) (car* y))) #f]
    [else (eq-word? (cdr* x) (cdr* y))]))

(define (lookup-word x)
  (let loop ([i object-list])
    (cond
      [(atom? i)
       (define a (mk-atom! PRIM-NONE "" 0))
       (set-name! a x)
       a]
      [(eq-word? (name (car* i)) x) (car* i)]
      [else (loop (cdr* i))])))

;; --- IO ---

(define (get-char!)
  (define b (read-byte in))
  (when (eof-object? b)
    (on-eof))
  b)

;; --- Parser ---

(define (separator? c mexp)
  (or (memv c '(32 10 40 41))
      (and mexp (memv c '(91 93 39 34)) #t)))

;; Reads one line (through \n) and splits it into tokens.
;; Each token is a reversed list of character codes.
(define (tokenize-line get-char mexp)
  (define line (lst NIL))
  (define err
    (let loop ([end line])
      (define c (get-char))
      (cond
        [(< c 0) c]
        [else
         (define node (lst c))
         (set-cdr! end node)
         (if (= c 10) #f (loop node))])))
  (cond
    [err err]
    [else
     (define tokens (lst NIL))
     (let loop ([line (cdr* line)] [end tokens] [word NIL])
       (unless (= line NIL)
         (define c (car* line))
         (define rest (cdr* line))
         (cond
           [(separator? c mexp)
            (define end*
              (if (= word NIL)
                  end
                  (let ([node (lst word)]) (set-cdr! end node) node)))
            (if (and (not (= c 32)) (not (= c 10)))
                (let ([node (lst (lst c))])
                  (set-cdr! end* node)
                  (loop rest node NIL))
                (loop rest end* NIL))]
           [(and (< 32 c) (< c 127)) (loop rest end (kons c word))]
           [else (loop rest end word)])))
     (cdr* tokens)]))

(define (only-digits? x)
  (let loop ([x x])
    (or (= x NIL)
        (let ([d (car* x)])
          (and (<= 48 d 57) (loop (cdr* x)))))))

(define (parse-decimal x)
  (let loop ([p x] [mult 1] [res 0])
    (if (atom? p)
        res
        (loop (cdr* p) (* mult 10) (+ res (* (- (car* p) 48) mult))))))

(define (token->expr token)
  (if (only-digits? token)
      (mk-num! (parse-decimal token))
      (lookup-word token)))

(define (in-word2)
  (let loop ()
    (when (= in-word-buffer NIL)
      (set! in-word-buffer
            (tokenize-line (λ () (let ([c (get-char!)]) (when echo? (put-char c)) c)) #t))
      (loop)))
  (define word (car* in-word-buffer))
  (set! in-word-buffer (cdr* in-word-buffer))
  (token->expr word))

;; Skips [nested [comments]].
(define (in-word)
  (define w (in-word2))
  (cond
    [(= w left-bracket)
     (let loop () (unless (= (in-word) right-bracket) (loop)))
     (in-word)]
    [else w]))

(define (read-list word-source mexp)
  (define first (lst NIL))
  (let loop ([last first])
    (define next (read-from word-source mexp #t))
    (unless (or (= next right-paren) (< next 0))
      (define node (lst next))
      (set-cdr! last node)
      (loop node)))
  (cdr* first))

(define (read-top mexp rparen-okay) (read-from in-word mexp rparen-okay))

(define (read-from word-source mexp rparen-okay)
  (define w (word-source))
  (define (sub) (read-from word-source #t #f))
  (cond
    [(= w right-paren) (if rparen-okay w NIL)]
    [(= w left-paren) (read-list word-source mexp)]
    [(not mexp) w]
    [(= w double-quote) (read-from word-source #f #f)]
    [(= w sym-cadr)
     (define sexp (sub))
     (lst sym-car (lst sym-cdr sexp))]
    [(= w sym-caddr)
     (define sexp (sub))
     (lst sym-car (lst sym-cdr (lst sym-cdr sexp)))]
    [(= w sym-utm)
     (define sexp (sub))
     (define inner (lst sym-quote (lst sym-eval (lst sym-read-exp))))
     (define try (lst sym-try sym-no-time-limit inner sexp))
     (lst sym-car (lst sym-cdr try))]
    [(= w sym-let)
     (define nm (sub))
     (define def (sub))
     (define body (sub))
     (define-values (nm* def*)
       (if (atom? nm)
           (values nm def)
           (let ([vars (cdr* nm)])
             (values (car* nm) (lst sym-quote (lst sym-lambda vars def))))))
     (lst (lst sym-quote (lst sym-lambda (lst nm*) body)) def*)]
    [(= (prim-args w) 0) w]
    [else
     ;; M-expression: read the remaining arity-1 arguments.
     (define first (lst w))
     (let loop ([last first] [i (sub1 (prim-args w))])
       (when (> i 0)
         (define node (lst (sub)))
         (set-cdr! last node)
         (loop node (sub1 i))))
     first]))

;; --- Evaluator ---

(define (ev e)
  (set! tapes (lst NIL))
  (set! display-enabled (lst 1))
  (set! captured-displays (lst NIL))
  (define v (ev* e sym-no-time-limit))
  (if (< v 0) (- v) v))

(define (ev* e d)
  (set! time-eval (add1 time-eval))
  (cond
    [(number? e) e]
    [(atom? e) (peek-value e)]
    [(= (car* e) sym-lambda) e]
    [else
     (define f (ev* (car* e) d))
     (define rest (cdr* e))
     (cond
       [(< f 0) f]
       [(= f sym-quote) (car* rest)]
       [(= f sym-if)
        (define v (ev* (car* rest) d))
        (cond
          [(< v 0) v]
          [(= v sym-false) (ev* (car* (cdr* (cdr* rest))) d)]
          [else (ev* (car* (cdr* rest)) d)])]
       [else
        (define args (ev-args rest d))
        (if (< args 0) args (apply-fn f args d))])]))

(define (apply-fn f args d)
  (define code (prim-code f))
  (cond
    [(> code PRIM-NONE) (apply-prim code args)]
    [(and (not (= d sym-no-time-limit)) (= 0 (to-int d))) (- sym-out-of-time)]
    [else
     (define d* (if (= d sym-no-time-limit) d (mk-num! (max 0 (sub1 (to-int d))))))
     (define x (car* args))
     (define y (car* (cdr* args)))
     (define z (car* (cdr* (cdr* args))))
     (cond
       [(= f sym-eval)
        (push-env!)
        (begin0 (ev* x d*) (pop-env!))]
       [(= f sym-try) (ev-try x y z d*)]
       [(= (car* f) sym-lambda)
        (define vars (car* (cdr* f)))
        (define body (car* (cdr* (cdr* f))))
        (bind! vars args)
        (begin0 (ev* body d*) (unbind! vars))]
       [else f])]))

(define (ev-try x y z d)
  (define limit (if (= x sym-no-time-limit) x (to-num x)))
  (define small-limit?
    (or (= limit sym-no-time-limit)
        (and (not (= d sym-no-time-limit)) (>= (to-int limit) (to-int d)))))
  (define limit* (if small-limit? d limit))
  (set! tapes (kons z tapes))
  (set! display-enabled (kons 0 display-enabled))
  (define stub (lst 0))
  (set-car! stub stub) ; car points at the end of the captured list
  (set! captured-displays (kons stub captured-displays))
  (push-env!)
  (define v (ev* y limit*))
  (pop-env!)
  (set! tapes (cdr* tapes))
  (set! display-enabled (cdr* display-enabled))
  (define stub-idx (car* captured-displays))
  (set! captured-displays (cdr* captured-displays))
  (define displays (cdr* stub-idx))
  (cond
    [(and small-limit? (= v (- sym-out-of-time))) v]
    [(< v 0) (lst sym-failure (- v) displays)]
    [else (lst sym-success v displays)]))

;; eval/try run in a clean environment: every atom bound to itself.
(define (push-env!)
  (let loop ([o object-list])
    (unless (= o NIL)
      (push-value! (car* o) (car* o))
      (loop (cdr* o))))
  (set-car! (stack sym-nil) NIL))

(define (pop-env!)
  (let loop ([o object-list])
    (unless (= o NIL)
      (pop-value! (car* o))
      (loop (cdr* o)))))

(define (bind! vars args)
  (unless (atom? vars)
    (bind! (cdr* vars) (cdr* args))
    (define v (car* vars))
    (when (atom? v) (push-value! v (car* args)))))

(define (unbind! vars)
  (unless (atom? vars)
    (define v (car* vars))
    (when (atom? v) (pop-value! v))
    (unbind! (cdr* vars))))

(define (ev-args e d)
  (if (= e NIL)
      NIL
      (let ([x (ev* (car* e) d)])
        (if (< x 0)
            x
            (let ([y (ev-args (cdr* e) d)])
              (if (< y 0) y (kons x y)))))))

;; --- Primitives ---

(define (apply-prim code args)
  (define x (car* args))
  (define (y) (car* (cdr* args)))
  (define (cmp) (compare (to-num x) (to-num (y))))
  (cond
    [(= code PRIM-CAR) (car* x)]
    [(= code PRIM-CDR) (cdr* x)]
    [(= code PRIM-CONS) (kons x (y))]
    [(= code PRIM-ATOM) (bool->sym (atom? x))]
    [(= code PRIM-EQ) (bool->sym (lisp-eq? x (y)))]
    [(= code PRIM-DISPLAY)
     (cond
       [(not (= (car* display-enabled) 0)) (print! "display" x)]
       [else
        ;; Inside try: append to the captured display list.
        (define stub-idx (car* captured-displays))
        (define old-end (car* stub-idx))
        (define new-end (lst x))
        (set-cdr! old-end new-end)
        (set-car! stub-idx new-end)
        x])]
    [(= code PRIM-DEBUG)
     (cond
       [debugs (set! debugs (cons x debugs)) x]
       [else (print! "debug" x)])]
    [(= code PRIM-APPEND)
     (append-list (if (atom? x) NIL x) (let ([y (y)]) (if (atom? y) NIL y)))]
    [(= code PRIM-LENGTH) (mk-num! (lisp-length x))]
    [(= code PRIM-LT) (bool->sym (< (cmp) 0))]
    [(= code PRIM-GT) (bool->sym (> (cmp) 0))]
    [(= code PRIM-LEQ) (bool->sym (<= (cmp) 0))]
    [(= code PRIM-GEQ) (bool->sym (>= (cmp) 0))]
    [(= code PRIM-PLUS) (binary-op x (y) +)]
    [(= code PRIM-TIMES) (binary-op x (y) *)]
    [(= code PRIM-POW) (binary-op x (y) expt)]
    [(= code PRIM-MINUS)
     (if (> (cmp) 0) (binary-op x (y) -) (mk-num! 0))]
    [(= code PRIM-2TO10) (mk-num! (base2->10 x))]
    [(= code PRIM-10TO2) (base10->2 (to-num x))]
    [(= code PRIM-SIZE) (mk-num! (size x))]
    [(= code PRIM-READ-BIT) (read-bit!)]
    [(= code PRIM-BITS)
     (define v (lst NIL))
     (set! q v)
     (serialize x write-char-bits!)
     (write-char-bits! 10)
     (cdr* v)]
    [(= code PRIM-READ-EXP)
     (define v (read-record!))
     (if (< v 0) v (read-from read-word #f #f))]))

(define (append-list x y)
  (if (= x NIL) y (kons (car* x) (append-list (cdr* x) y))))

(define (lisp-eq? x y)
  (cond
    [(= x y) #t]
    [(and (number? x) (number? y)) (= (compare x y) 0)]
    [(or (number? x) (number? y)) #f]
    [(or (atom? x) (atom? y)) #f]
    [else (and (lisp-eq? (car* x) (car* y)) (lisp-eq? (cdr* x) (cdr* y)))]))

(define (compare x y)
  (define a (to-int x))
  (define b (to-int y))
  (cond [(< a b) -1] [(> a b) 1] [else 0]))

(define (to-num x) (if (number? x) x NIL))

(define (lisp-length x)
  (let loop ([p x] [n 0])
    (if (atom? p) n (loop (cdr* p) (add1 n)))))

(define (base2->10 x)
  (let loop ([p x] [res 0])
    (if (atom? p)
        res
        (let* ([bit (car* p)]
               [v (if (and (number? bit) (= 0 (to-int bit))) 0 1)])
          (loop (cdr* p) (+ (* 2 res) v))))))

(define (base10->2 x)
  (let loop ([n (to-int x)] [bits NIL])
    (if (= n 0)
        bits
        (loop (arithmetic-shift n -1)
              (kons (if (odd? n) sym-one sym-zero) bits)))))

(define (size x)
  (cond
    [(number? x) (string-length (number->string (to-int x)))]
    [(atom? x) (lisp-length (name x))]
    [else
     (let loop ([p x] [sum 0])
       (if (atom? p)
           (+ sum 2)
           (let* ([sum (+ sum (size (car* p)))]
                  [p (cdr* p)])
             (loop p (if (atom? p) sum (add1 sum))))))]))

;; --- Tape ---

(define (read-bit!)
  (define t (car* tapes))
  (cond
    [(atom? t) (- sym-out-of-data)]
    [else
     (define bit (car* t))
     (set-car! tapes (cdr* t))
     (if (and (number? bit) (= 0 (to-int bit))) sym-zero sym-one)]))

(define (write-char-bits! c)
  (for ([i (in-range 7 -1 -1)])
    (define node (lst (if (bitwise-bit-set? c i) sym-one sym-zero)))
    (set-cdr! q node)
    (set! q node)))

(define (read-char!)
  (let loop ([i 0] [c 0])
    (if (= i 8)
        c
        (let ([b (read-bit!)])
          (if (< b 0)
              b
              (loop (add1 i) (bitwise-ior (arithmetic-shift c 1)
                                          (if (= b sym-zero) 0 1))))))))

(define (read-record!)
  (define tokens (tokenize-line read-char! #f))
  (cond
    [(< tokens 0) tokens]
    [else (set! buffer2 tokens) 0]))

(define (read-word)
  (cond
    [(= buffer2 NIL) right-paren]
    [else
     (define word (car* buffer2))
     (set! buffer2 (cdr* buffer2))
     (token->expr word)]))

;; --- Main ---

(define (reset! input output)
  (set! in input)
  (set! halt void)
  (set! on-overflow void)
  (set! on-eof void)
  (set! echo? #t)
  (set! debugs #f)
  (set! out output)
  (set! object-list NIL)
  (set! next-free 0)
  (set! col 0)
  (set! time-eval 0)
  (set! tapes NIL)
  (set! display-enabled NIL)
  (set! captured-displays NIL)
  (set! q NIL)
  (set! buffer2 NIL)
  (set! in-word-buffer NIL))

;; Top-level define: binds the atom's global value.
(define (top-define! e print?)
  (define args (cdr* e))
  (define nm (car* args))
  (define def (car* (cdr* args)))
  (define-values (sym val)
    (if (atom? nm)
        (values nm def)
        (values (car* nm) (lst sym-lambda (cdr* nm) def))))
  (when print?
    (print! "define" sym)
    (print! "value" val))
  (set-car! (stack sym) val))

;; Reads a transcript program from input and writes the run to output,
;; exactly as `./lisp < input > output` does.
(define (run-machine [input (current-input-port)] [output (current-output-port)])
  (reset! input output)
  (let/ec k
    (set! halt k)
    (set! on-overflow
          (λ ()
            (write-string "Storage overflow!\n" out)
            (halt)))
    (set! on-eof
          (λ ()
            (fprintf out "End of LISP Run\n\nCalls to eval = ~a\nCalls to cons = ~a\n"
                     time-eval next-free)
            (halt)))
    (write-string "LISP Interpreter Run\n" out)
    (init!)
    (let loop ()
      (newline out)
      (define e (read-top #t #f))
      (newline out)
      (cond
        [(= (car* e) sym-define) (top-define! e #t)]
        [else
         (print! "expression" e)
         (print! "value" (ev e))])
      (loop)))
  (flush-output out))

;; --- API: Racket data in and out of a fresh machine ---

(define (call-with-fresh-machine input thunk)
  (reset! input (current-output-port))
  (set! echo? #f)
  (set! on-overflow
        (λ () (raise (exn:fail "ait: storage overflow" (current-continuation-marks)))))
  (set! halt
        (λ () (raise (exn:fail "ait: machine halted" (current-continuation-marks)))))
  (init!)
  (begin0 (thunk) (flush-output out)))

(define (node->datum x)
  (cond
    [(number? x) (to-int x)]
    [(= x NIL) '()]
    [(atom? x) (string->symbol (name->string (name x)))]
    [else
     (let loop ([p x])
       (if (atom? p) '() (cons (node->datum (car* p)) (loop (cdr* p)))))]))

(define (name->string x)
  (define o (open-output-string))
  (serialize-name x (λ (c) (write-char (integer->char c) o)))
  (get-output-string o))

(define (datum->node d)
  (cond
    [(exact-nonnegative-integer? d) (mk-num! d)]
    [(null? d) NIL]
    [(symbol? d) (lookup-word (mk-string! (atom-name d)))]
    [(and (pair? d) (list? d))
     (let loop ([d d])
       (if (null? d) NIL (let ([x (datum->node (car d))]) (kons x (loop (cdr d))))))]
    [else
     (raise-argument-error
      'ait "a non-negative integer, symbol, or proper list of those" d)]))

;; Atom names are what the reader can produce: printable, no parentheses.
(define (atom-name sym)
  (define s (symbol->string sym))
  (unless (and (positive? (string-length s))
               (for/and ([c (in-string s)])
                 (and (char<? #\space c #\rubout) (not (memv c '(#\( #\)))))))
    (raise-argument-error 'ait "an atom name of printable characters" sym))
  s)

;; Parses M-expression text into a list of S-expressions.
(define (lisp-parse text)
  (call-with-fresh-machine
   (open-input-string (string-append text "\n"))
   (λ ()
     (let loop ([acc '()])
       (define started? #f)
       (define e
         (let/ec k
           (set! on-eof
                 (λ ()
                   (when started?
                     (error 'lisp-parse "incomplete expression at end of: ~a" text))
                   (k eof)))
           (read-from (λ () (begin0 (in-word) (set! started? #t))) #t #f)))
       (if (eof-object? e)
           (reverse acc)
           (loop (cons (node->datum e) acc)))))))

;; The result of running an expression, as from try:
;; status is 'success or 'failure; on failure value is the reason.
;; debugs are the values passed to debug, in order.
(struct outcome (status value displays debugs evals conses) #:transparent)

;; Evaluates expr like a try, but in the top-level environment so that
;; defs (a list of define forms) are visible. limit is a number of
;; steps or #f for no limit; tape is the list of bits read-bit consumes.
(define (lisp-run expr #:time [limit #f] #:tape [tape '()] #:defs [defs '()])
  (call-with-fresh-machine
   (open-input-bytes #"")
   (λ ()
     (for ([d (in-list defs)])
       (top-define! (datum->node d) #f))
     (define e (datum->node expr))
     (set! tapes (lst (datum->node tape)))
     (set! display-enabled (lst 0))
     (define stub (lst 0))
     (set-car! stub stub)
     (set! captured-displays (lst stub))
     (define d (if limit (mk-num! limit) sym-no-time-limit))
     (set! debugs '())
     (define evals0 time-eval)
     (define conses0 next-free)
     (define v (ev* e d))
     (outcome (if (< v 0) 'failure 'success)
              (node->datum (if (< v 0) (- v) v))
              (node->datum (cdr* stub))
              (map node->datum (reverse debugs))
              (- time-eval evals0)
              (- next-free conses0)))))
