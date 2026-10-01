#lang ait/scribble
@(require racket/runtime-path racket/file racket/list)

@title{Elegant S-expressions cannot be proved elegant}

A @tt{#lang ait/scribble} port of @tt{godel.l}, from Chaitin's
@italic{The Limits of Mathematics}. Each claim below is checked while this
document is built: run @tt{racket -S src lm/godel.scrbl} to check it, or
@tt{raco scribble} to render it.

@section{The claim}

An S-expression is @italic{elegant} if no smaller S-expression has the same
value. A formal axiomatic system (FAS) is modelled as a LISP expression
that displays the S-expressions it proves elegant. Its LISP complexity
@m{N} is at most its size.

@theorem{A formal axiomatic system of LISP complexity @m{N} cannot prove
that any S-expression of size greater than @m{N + 410} is elegant.}

@section{The searcher}

The proof is a program. Given a FAS, it runs it for longer and longer,
waiting for a theorem “@m{s} is elegant” with @m{\mathrm{size}(s) > n}, and
then evaluates @m{s}. Here the FAS and the constant are holes:

@define-lisp[searcher]{
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
}

For the argument to work, @m{n} must be the searcher's own size: the size of
the FAS plus everything else. Everything else is the searcher's
@italic{overhead}, which includes the digits of the constant itself.
@tt{godel.l} types the constant 410; here @tt{fix-overhead} derives it as
the least constant at least as large as the overhead it creates.

@(define searcher* (fix-overhead searcher))
@(define c (overhead searcher*))
@(define (expression fas) (plug searcher* #:fas fas))

@expect[c ⇒ 410 #:label "the searcher's overhead c"]

The constant does not depend on the FAS: the expression's size is always
@m{\mathrm{size}(\mathit{FAS}) + c}.

@(define (toy-fas k) @lisp{display ^ 10 @k})
@(define fases
   (list (toy-fas 430)
         (toy-fas 5)
         @lisp{cons display 'x cons display '(a b) display ^ 10 500}
         @lisp{let (f x) if = x 0 nil cons display x (f - x 1) (f 10)}))

@property["size(expression) = size(FAS) + c, for four different FASes"
          ([fas fases])
  (= (size (expression fas)) (+ (size fas) c))]

@proof{Suppose the FAS has complexity @m{N} and proves that some @m{s} with
@m{\mathrm{size}(s) > N + c} is elegant. Plug the FAS's elegant
expression, of size @m{N}, into the searcher. The result has size
@m{N + c}, and it eventually finds @m{s} and evaluates it. So it has the
same value as @m{s} while being smaller than @m{s}: @m{s} is not elegant,
and the FAS proved something false.}

@section{Running it}

A toy FAS that “proves” @m{10^k}, which has @m{k + 1} digits, is elegant:

@lisp-code{display ^ 10 430}

Plugging it into the searcher with @m{k = 430} gives exactly the
expression @tt{godel.l} defines, and with @m{k = 429} the one it runs
second:

@(define-runtime-path godel.l "godel.l")
@(define godel-forms (lisp* (file->string godel.l)))

@expect[(expression (toy-fas 430)) ⇒ (caddr (first godel-forms))
        #:label "the searcher with k = 430 is godel.l's expression"]
@expect[(expression (toy-fas 429)) ⇒ (fourth godel-forms)
        #:label "the searcher with k = 429 is godel.l's second expression"]
@expect[(size (expression (toy-fas 430))) ⇒ 430
        #:label "its size, as godel.r reports"]

@show-lisp[(expression (toy-fas 430))]

@tt{godel.l} shows both sides of the threshold by repeating the whole
expression. Here the searcher runs for a range of @m{k}:

@threshold[(expression (toy-fas k))
  #:vary k #:over '(427 428 429 430 431 432)
  #:observe (λ (o) (if (number? (outcome-value o)) 'refutes-the-fas 'finds-nothing))
  #:flips-at 430
  #:explain "With N = 20 the searcher's size is 430, so it refutes the FAS
             once 10^k has more than 430 digits."]

At @m{k = 430} the FAS claims that @m{s = 10^{430}} is elegant. The
searcher computes the same value while being smaller:

@(define fas (toy-fas 430))
@(define (found fas)
   (for/first ([x (outcome-displays (run fas))]
               #:when (> (size x) (+ c (size fas))))
     x))
@(define s (found fas))

@expect[(size s) ⇒ 431 #:label "size(s)"]
@bound[(size (expression fas)) < (size s) #:label "size(expression) < size(s)"]
@expect[(value (expression fas)) ⇒ (value s) #:label "value(expression) = value(s)"]

And in general: whenever the searcher evaluates some @m{s}, @m{s} is larger
than @m{N + c} and the searcher has its value.

@property["every s the searcher evaluates has size > size(FAS) + c"
          ([fas fases])
  (define v (outcome-value (run (expression fas))))
  (define s (found fas))
  (if s
      (and (> (size s) (+ (size fas) c)) (equal? v (value s)))
      (eq? v 'failure))]
