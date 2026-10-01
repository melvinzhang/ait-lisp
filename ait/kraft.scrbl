#lang ait/scribble
@(require racket/runtime-path racket/file racket/list racket/string)

@title{The Kraft inequality criterion for constructing computers}

A @tt{#lang ait/scribble} port of @tt{kraft.l}, from Chaitin's
@italic{Exploring Randomness}. Each claim below is checked while this
document is built: run @tt{racket -S src ait/kraft.scrbl} to check it, or
@tt{raco scribble} to render it.

@section{The claim}

The input is a list of @italic{requirements} @tt{(output size)}: “some
program of this size should produce this output”. The output is a list
of @italic{assignments} @tt{(program output)}, where the programs are
bit strings and no program is a prefix of another. Prefix-free programs
are what a self-delimiting computer needs, and @tt{exec.l} runs them.

@theorem{If the requirements satisfy the Kraft inequality
@mm{\sum_{(x,\,n)} 2^{-n} \le 1}
then every requirement is met: each output gets a program of exactly
the requested size, and the programs are prefix-free.}

@section{The algorithm}

The @italic{free space pool} is a list of prefixes all of whose
extensions are unassigned programs. Initially it holds only the empty
string. Each requirement takes the first piece in the pool, which is kept
in lexicographic order, that is big enough. The program is that piece
extended with 0s to the requested size, and the rest of the piece goes
back into the pool as @tt{prefix0…01}, …, @tt{prefix01}, @tt{prefix1}.

@define-lisp*[kraft-defs]{
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
}

@(define-runtime-path kraft.l "kraft.l")
@expect[kraft-defs
        ⇒ (filter (λ (f) (and (pair? f) (eq? 'define (car f))))
                  (lisp* (file->string kraft.l)))
        #:label "these are exactly the definitions in kraft.l"]

@(define (kraft-run reqs) (run @lisp{(kraft '@reqs)} #:defs kraft-defs))
@(define (assignments reqs) (outcome-value (kraft-run reqs)))
@(define (pools reqs) (outcome-debugs (kraft-run reqs)))
@(define refused 'not-enough-storage!)
@(define (bitstring b) (if (null? b) "ε" (string-append* (map number->string b))))

@section{Examples}

The examples @tt{kraft.l} runs give the values @tt{kraft.r} shows. A
requirement that cannot be met is answered with
@tt{not-enough-storage!}.

@expect[(assignments '((x 1) (y 2))) ⇒ '(((0) x) ((1 0) y))]
@expect[(assignments '((x 0) (y 1))) ⇒ `((() x) ,refused)]
@expect[(assignments '((a 1) (b 0) (c 1))) ⇒ `(((0) a) ,refused ((1) c))]
@expect[(assignments '((e 5) (c 3) (d 4) (a 1) (b 2)))
        ⇒ '(((0 0 0 0 0) e) ((0 0 1) c) ((0 0 0 1) d) ((1) a) ((0 1) b))]

Requirements of sizes 1, 2, 3, … get the programs 0, 10, 110, …, as
@tt{kraft.l}'s comments say; then the pool is always a single piece.

@expect[(map car (assignments (for/list ([i 6]) (list i (add1 i)))))
        ⇒ '((0) (1 0) (1 1 0) (1 1 1 0) (1 1 1 1 0) (1 1 1 1 1 0))
        #:label "programs for sizes 1 to 6"]

Here is the pool, as @tt{debug} shows it, while the last example is
assigned:

@(let ([reqs '((e 5) (c 3) (d 4) (a 1) (b 2))])
   (tabular #:style "AitTable"
            #:row-properties '(bottom-border ())
            (cons (list "requirement" "program" "free pool afterwards")
                  (for/list ([pool (pools reqs)] [r (cons #f reqs)] [a (cons #f (assignments reqs))])
                    (list (if r (tt (show r)) "start")
                          (if a (tt (bitstring (car a))) "")
                          (tt (string-join (map bitstring pool) " ")))))))

@section{Why it works}

@tt{kraft.l} argues from a @italic{key fact}: with this first-fit rule
the free pieces are always distinct powers of two, in increasing order
of size. So if a request does not fit, it is at least twice the largest
piece. The free space is less than twice the largest piece, so granting
the request would have broken the Kraft inequality.

These claims are checked on random requirement lists, of up to 8
requirements of sizes 0 to 6:

@(define (measure size) (expt 1/2 size))
@(define (kraft-sum reqs) (for/sum ([r reqs]) (measure (cadr r))))
@(define cases
   (parameterize ([current-pseudo-random-generator (make-pseudo-random-generator)])
     (random-seed 2017)
     (for/list ([i 300])
       (for/list ([j (add1 (random 8))])
         (list (string->symbol (format "o~a" j)) (random 7))))))
@(define satisfiable (filter (λ (r) (<= (kraft-sum r) 1)) cases))
@(define unsatisfiable (filter (λ (r) (> (kraft-sum r) 1)) cases))
@(define (prefix? a b) (and (<= (length a) (length b)) (equal? a (take b (length a)))))
@(define (prefix-free? ps)
   (for*/and ([(a i) (in-indexed ps)] [(b j) (in-indexed ps)] #:unless (= i j))
     (not (prefix? a b))))
@(define (granted reqs j)
   (for/sum ([q (take reqs j)] [a (assignments reqs)] #:unless (eq? a refused))
     (measure (cadr q))))

@expect[(list (length satisfiable) (length unsatisfiable)) ⇒ '(120 180)
        #:label "satisfiable and unsatisfiable cases"]

@property["if the Kraft inequality holds, every requirement is met exactly"
          ([reqs satisfiable])
  (equal? (map (λ (a) (list (length (car a)) (cadr a))) (assignments reqs))
          (map (λ (r) (list (cadr r) (car r))) reqs))]

@property["the assigned programs are prefix-free" ([reqs cases])
  (prefix-free? (map car (filter pair? (assignments reqs))))]

@property["a request is refused only if it would overflow the unit interval"
          ([reqs unsatisfiable])
  (for/and ([r reqs] [i (in-naturals)]
            #:when (eq? refused (list-ref (assignments reqs) i)))
    (> (+ (granted reqs i) (measure (cadr r))) 1))]

@property["key fact: free pieces are distinct powers of two in increasing size"
          ([reqs cases])
  (for/and ([pool (pools reqs)])
    (define lengths (map length pool))
    (equal? lengths (sort (remove-duplicates lengths) >)))]

@property["the pool stays in lexicographic order and accounts for all space"
          ([reqs cases])
  (for/and ([pool (pools reqs)] [j (in-naturals)])
    (and (equal? pool (sort pool (λ (a b) (string<? (bitstring a) (bitstring b)))))
         (= 1 (+ (granted reqs j) (for/sum ([p pool]) (measure (length p)))))))]

Finally, @tt{exec.l} relies on @tt{kraft} being monotone: as it learns
more requirements it reruns @tt{kraft} on the longer list, and that must
only extend the earlier assignments.

@property["it never changes its mind: more requirements only add assignments"
          ([reqs cases])
  (for/and ([j (in-range (length reqs))])
    (equal? (assignments (take reqs j)) (take (assignments reqs) j)))]
