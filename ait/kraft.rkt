#lang ait
;; KRAFT INEQUALITY CRITERION FOR CONSTRUCTING COMPUTERS
;; A #lang ait port of kraft.l. Run with: racket -S src ait/kraft.rkt
;;
;; Input: requirements (output size-of-program). Output: assignments
;; (program output) where the programs are prefix-free bit strings, so
;; they can be the programs of a self-delimiting computer (exec.l runs it).
;; kraft.l claims that this works whenever the Kraft inequality
;;     sum over requirements of 2^-size  <=  1
;; holds. Here the claims made in its comments are checked instead.

(require racket/runtime-path racket/file racket/list racket/string racket/format)

;; --- The object code, unchanged from kraft.l ---

;; The free space pool is a list of prefixes, all of whose extensions are
;; unassigned. Each requirement takes the first piece in the pool (kept in
;; lexicographic order) that is big enough; the leftover part of that piece
;; goes back as prefix00..01, ..., prefix01, prefix1.
(define kraft-defs
  @lisp*{
    define (extend-with-0s bit-string [to] given-length)
       if = length bit-string given-length  [then]
          bit-string  [else]
       append (extend-with-0s bit-string [to] - given-length 1)
              cons 0 nil

    define (remove-piece free-prefix size-of-program)
       if = size-of-program length free-prefix
           nil  [then no storage left, else]
       cons append (extend-with-0s free-prefix [to] - size-of-program 1)
                   cons 1 nil
            (remove-piece free-prefix - size-of-program 1)

    define (make-assignments free-space-pool requirements)
       let free-space-pool   debug free-space-pool
       if  atom requirements nil
       let requirement       car  requirements
       let requirements      cdr  requirements
       let output-of-program car  requirement
       let size-of-program   cadr requirement
       let already-scanned   nil
       let not-yet-scanned   free-space-pool
       let (loop-thru-free-space-pool)
           if atom not-yet-scanned
              cons not-enough-storage!
                   (make-assignments free-space-pool requirements)
           let free-prefix      car not-yet-scanned
           let not-yet-scanned  cdr not-yet-scanned
           if < size-of-program length free-prefix
              let already-scanned
                  append already-scanned
                         cons free-prefix nil
              (loop-thru-free-space-pool)
           let free-space-pool
               append already-scanned
               append (remove-piece free-prefix size-of-program)
                      not-yet-scanned
           let assignment
               cons (extend-with-0s free-prefix [to] size-of-program)
               cons output-of-program
                    nil
           cons assignment
                (make-assignments free-space-pool requirements)
       (loop-thru-free-space-pool)

    define (kraft requirements)
       let free-space-pool '(()) [everything free]
       (make-assignments free-space-pool requirements)
  })

;; These are exactly the definitions in kraft.l.
(define-runtime-path kraft.l "kraft.l")
(expect kraft-defs
        ⇒ (filter (λ (f) (and (pair? f) (eq? 'define (car f))))
                  (lisp* (file->string kraft.l))))

;; --- Running it ---

(define (kraft-run reqs) (run @lisp{(kraft '@reqs)} #:defs kraft-defs))
(define (assignments reqs) (outcome-value (kraft-run reqs)))
(define (pools reqs) (outcome-debugs (kraft-run reqs))) ; pool before each step

(define refused 'not-enough-storage!)

;; The examples kraft.l runs, with the values kraft.r shows.
(expect (assignments '((x 1) (y 2))) ⇒ '(((0) x) ((1 0) y)))
(expect (assignments '((x 0) (y 1))) ⇒ `((() x) ,refused))
(expect (assignments '((a 1) (b 0) (c 1))) ⇒ `(((0) a) ,refused ((1) c)))
(expect (assignments '((e 5) (c 3) (d 4) (a 1) (b 2)))
        ⇒ '(((0 0 0 0 0) e) ((0 0 1) c) ((0 0 0 1) d) ((1) a) ((0 1) b)))

;; The example from kraft.l's comments: sizes 1, 2, 3, ... give 0, 10, 110, ...
(expect (map car (assignments (for/list ([i 6]) (list i (add1 i)))))
        ⇒ '((0) (1 0) (1 1 0) (1 1 1 0) (1 1 1 1 0) (1 1 1 1 1 0)))

;; How the pool evolves: free pieces are distinct powers of two,
;; in order of increasing size.
(define (bitstring b) (if (null? b) "ε" (string-append* (map number->string b))))
(let ([reqs '((e 5) (c 3) (d 4) (a 1) (b 2))])
  (printf "\nfree pool while assigning ~a:\n" (show reqs))
  (for ([pool (pools reqs)] [r (cons #f reqs)] [a (cons #f (assignments reqs))])
    (printf "   ~a ~a\n"
            (~a (if r (format "~a gets ~a" (show r) (bitstring (car a))) "start")
                #:min-width 18)
            (string-join (map bitstring pool) " "))))
(newline)

;; --- Checking kraft.l's claims on random requirement lists ---

(define (measure size) (expt 1/2 size))
(define (kraft-sum reqs) (for/sum ([r reqs]) (measure (cadr r))))

(define cases
  (parameterize ([current-pseudo-random-generator (make-pseudo-random-generator)])
    (random-seed 2017)
    (for/list ([i 300])
      (for/list ([j (add1 (random 8))])
        (list (string->symbol (format "o~a" j)) (random 7))))))
(define satisfiable (filter (λ (r) (<= (kraft-sum r) 1)) cases))
(define unsatisfiable (filter (λ (r) (> (kraft-sum r) 1)) cases))
(expect (and (> (length satisfiable) 50) (> (length unsatisfiable) 50)) ⇒ #t)

(define (prefix? a b) (and (<= (length a) (length b)) (equal? a (take b (length a)))))
(define (prefix-free? ps)
  (for*/and ([(a i) (in-indexed ps)] [(b j) (in-indexed ps)] #:unless (= i j))
    (not (prefix? a b))))

(property "if the Kraft inequality holds, every requirement is met exactly"
  ([reqs satisfiable])
  (equal? (map (λ (a) (list (length (car a)) (cadr a))) (assignments reqs))
          (map (λ (r) (list (cadr r) (car r))) reqs)))

(property "the assigned programs are prefix-free"
  ([reqs cases])
  (prefix-free? (map car (filter pair? (assignments reqs)))))

(property "a request is refused only if it would overflow the unit interval"
  ([reqs unsatisfiable])
  (for/and ([r reqs] [i (in-naturals)] #:when (eq? refused (list-ref (assignments reqs) i)))
    (define granted
      (for/sum ([q (take reqs i)] [a (assignments reqs)] #:unless (eq? a refused))
        (measure (cadr q))))
    (> (+ granted (measure (cadr r))) 1)))

(property "it never changes its mind: more requirements only add assignments"
  ([reqs cases])
  (for/and ([j (in-range (length reqs))])
    (equal? (assignments (take reqs j)) (take (assignments reqs) j))))

;; The "key fact" kraft.l's comments use to prove the claim above.
(property "key fact: free pieces are distinct powers of two in increasing size"
  ([reqs cases])
  (for/and ([pool (pools reqs)])
    (define lengths (map length pool))
    (equal? lengths (sort (remove-duplicates lengths) >))))

(property "the pool stays in lexicographic order and accounts for all space"
  ([reqs cases])
  (for/and ([pool (pools reqs)] [j (in-naturals)])
    (define granted
      (for/sum ([q (take reqs j)] [a (assignments reqs)] #:unless (eq? a refused))
        (measure (cadr q))))
    (and (equal? pool (sort pool (λ (a b) (string<? (bitstring a) (bitstring b)))))
         (= 1 (+ granted (for/sum ([p pool]) (measure (length p))))))))
